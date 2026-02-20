//
//  MainViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// MainViewModel.swift
// Features/Main/ViewModels/
//
// Owns all state for the Main (tracking) tab.
// Calculation engine: raw transactions → FinancialSummary → SmartInsights → AIContext
// Views never touch DatabaseService directly.

import Foundation

@Observable
final class MainViewModel {

    // MARK: - Raw Data
    var transactions:        [Transaction]       = []
    var recurringTemplates:  [RecurringTemplate] = []
    var budgetLimits:        [BudgetLimit]       = []
    var goals:               [FinancialGoal]     = []
    var recentSnapshots:     [MonthlySnapshot]   = []

    // MARK: - Computed State (rebuilt after every data change)
    private(set) var summary:       FinancialSummary?
    private(set) var insights:      [SmartInsight]   = []
    private(set) var aiContext:     AIFinancialContext?

    // MARK: - UI State
    var selectedMonth:        String = currentMonthString()  // "2026-02"
    var isLoadingHome:        Bool   = false
    var isLoadingTransactions: Bool  = false
    var isSubmitting:         Bool   = false
    var errorMessage:         String?

    // MARK: - Add Transaction Form State
    var formType:        TransactionType     = .expense
    var formAmount:      String              = ""
    var formCategory:    TransactionCategory = .food
    var formNote:        String              = ""
    var formDate:        Date                = Date()
    var formIsRecurring: Bool                = false

    // MARK: - Dependencies
    private let db:      DatabaseService
    private let session: UserSession
    private var streamTask: Task<Void, Never>?

    init(db: DatabaseService, session: UserSession) {
        self.db      = db
        self.session = session
    }

    private var uid: String? { session.user?.id }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Load Home
    // Called once when Main tab appears
    // ─────────────────────────────────────────────────────────────────────────

    func loadHome() async {
        guard let uid else { return }
        isLoadingHome = true
        errorMessage  = nil
        defer { isLoadingHome = false }

        do {
            // Fetch supporting data in parallel
            async let limitsTask    = db.fetchBudgetLimits(uid: uid)
            async let goalsTask     = db.fetchGoals(uid: uid)
            async let snapshotsTask = db.fetchRecentSnapshots(uid: uid, limit: 6)
            async let recurringTask = db.fetchRecurringTemplates(uid: uid)

            let (limits, fetchedGoals, snapshots, recurring) =
                try await (limitsTask, goalsTask, snapshotsTask, recurringTask)

            budgetLimits       = limits
            goals              = fetchedGoals
            recentSnapshots    = snapshots
            recurringTemplates = recurring

            // Start real-time transaction stream
            startTransactionStream(uid: uid)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Real-Time Stream
    // Keeps transactions always fresh — recalculates on every update
    // ─────────────────────────────────────────────────────────────────────────

    private func startTransactionStream(uid: String) {
        streamTask?.cancel()
        streamTask = Task {
            for await updated in db.streamTransactions(uid: uid) {
                guard !Task.isCancelled else { break }
                self.transactions = updated
                self.recalculate()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Add Transaction
    // ─────────────────────────────────────────────────────────────────────────

    func addTransaction() async -> Bool {
        guard let uid else { return false }
        guard let amount = Double(formAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount."
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let tx = Transaction(
            id:          nil,
            type:        formType,
            amount:      amount,
            category:    formCategory,
            date:        formDate,
            note:        formNote,
            isRecurring: formIsRecurring,
            recurringID: nil
        )

        do {
            try db.addTransaction(tx, uid: uid)

            // If recurring, also save a template
            if formIsRecurring {
                let template = RecurringTemplate(
                    id:        UUID().uuidString,
                    type:      formType,
                    amount:    amount,
                    category:  formCategory,
                    note:      formNote,
                    frequency: .monthly,
                    startDate: formDate,
                    isActive:  true
                )
                try db.createRecurringTemplate(template, uid: uid)
                recurringTemplates.append(template)
            }

            clearForm()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteTransaction(_ transaction: Transaction) async {
        guard let uid, let id = transaction.id else { return }
        do {
            try await db.deleteTransaction(uid: uid, transactionID: id)
            // Stream will auto-update transactions + trigger recalculate
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Goals
    // ─────────────────────────────────────────────────────────────────────────

    func addGoal(title: String, targetAmount: Double, deadline: Date?) async -> Bool {
        guard let uid else { return false }
        isSubmitting = true
        defer { isSubmitting = false }

        let goal = FinancialGoal(
            id:            UUID().uuidString,
            title:         title,
            targetAmount:  targetAmount,
            currentAmount: 0,
            deadline:      deadline,
            isCompleted:   false,
            createdAt:     Date()
        )

        do {
            try db.createGoal(goal, uid: uid)
            goals.append(goal)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateGoalProgress(goal: FinancialGoal, newAmount: Double) async {
        guard let uid, let id = goal.id else { return }
        do {
            try db.updateGoalProgress(uid: uid, goalID: id, currentAmount: newAmount)
            if let index = goals.firstIndex(where: { $0.id == id }) {
                goals[index].currentAmount = newAmount
                if newAmount >= goals[index].targetAmount {
                    goals[index].isCompleted = true
                    try db.markGoalCompleted(uid: uid, goalID: id)
                }
            }
            recalculate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGoal(_ goal: FinancialGoal) async {
        guard let uid, let id = goal.id else { return }
        do {
            try await db.deleteGoal(uid: uid, goalID: id)
            goals.removeAll { $0.id == id }
            recalculate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Budget Limits
    // ─────────────────────────────────────────────────────────────────────────

    func saveBudgetLimits(_ limits: [BudgetLimit]) async {
        guard let uid else { return }
        do {
            try db.saveBudgetLimits(limits, uid: uid)
            budgetLimits = limits
            recalculate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func budgetLimit(for category: TransactionCategory) -> Double? {
        budgetLimits.first { $0.category == category }?.limit
    }

    func budgetUsagePercentage(for category: TransactionCategory) -> Double {
        guard let limit = budgetLimit(for: category), limit > 0,
              let summary else { return 0 }
        return min((summary.amount(for: category) / limit) * 100, 100)
    }

    func isBudgetExceeded(for category: TransactionCategory) -> Bool {
        guard let limit = budgetLimit(for: category),
              let summary else { return false }
        return summary.amount(for: category) > limit
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Month Navigation
    // ─────────────────────────────────────────────────────────────────────────

    func goToPreviousMonth() {
        selectedMonth = offsetMonth(selectedMonth, by: -1)
        recalculate()
    }

    func goToNextMonth() {
        let next = offsetMonth(selectedMonth, by: 1)
        // Don't allow future months
        guard next <= Self.currentMonthString() else { return }
        selectedMonth = next
        recalculate()
    }

    var isCurrentMonth: Bool {
        selectedMonth == Self.currentMonthString()
    }

    var selectedMonthDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: selectedMonth) else { return selectedMonth }
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Accessors for Views
    // ─────────────────────────────────────────────────────────────────────────

    var currentMonthTransactions: [Transaction] {
        transactions.filter { $0.month == selectedMonth }
    }

    var currentMonthExpenses: [Transaction] {
        currentMonthTransactions.filter { $0.isExpense }
    }

    var currentMonthIncome: [Transaction] {
        currentMonthTransactions.filter { $0.isIncome }
    }

    func transactions(for category: TransactionCategory) -> [Transaction] {
        currentMonthExpenses.filter { $0.category == category }
    }

    var activeGoals: [FinancialGoal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [FinancialGoal] {
        goals.filter { $0.isCompleted }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Calculation Engine
    // Called after every data change — never called from views directly
    // ─────────────────────────────────────────────────────────────────────────

    private func recalculate() {
        summary   = buildSummary()
        insights  = buildInsights()
        aiContext = buildAIContext()
    }

    private func buildSummary() -> FinancialSummary {
        let monthTx      = currentMonthTransactions
        let monthExpenses = monthTx.filter { $0.isExpense }
        let monthIncome   = monthTx.filter { $0.isIncome  }

        let totalIncome   = monthIncome.reduce(0)  { $0 + $1.amount }
        let totalExpenses = monthExpenses.reduce(0) { $0 + $1.amount }
        let netBalance    = totalIncome - totalExpenses
        let savingsRate   = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0

        // Daily average — expenses so far this month divided by current day
        let dayOfMonth    = Calendar.current.component(.day, from: Date())
        let dailyAverage  = isCurrentMonth
            ? (totalExpenses / Double(max(dayOfMonth, 1)))
            : (totalExpenses / 30.0)

        // Category breakdown
        var byCategory: [TransactionCategory: Double] = [:]
        for tx in monthExpenses {
            byCategory[tx.category, default: 0] += tx.amount
        }

        // Overall balance (all time)
        let allTimeIncome   = transactions.filter { $0.isIncome  }.reduce(0) { $0 + $1.amount }
        let allTimeExpenses = transactions.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
        let currentBalance  = allTimeIncome - allTimeExpenses

        // Total savings — balance + any pre-existing savings from onboarding
        let onboardingSavings = session.user?.financialProfile?.currentSavings ?? 0
        let totalSavings      = max(currentBalance + onboardingSavings, 0)

        // Financial stability
        let monthlyExpenseBaseline = totalExpenses > 0 ? totalExpenses : 1
        let stabilityRatio         = totalSavings / monthlyExpenseBaseline
        let stability: FinancialStability = {
            if stabilityRatio >= 3 { return .stable   }
            if stabilityRatio >= 1 { return .moderate }
            return .risky
        }()

        // Discretionary ratio (entertainment + shopping)
        let discretionary = (byCategory[.entertainment] ?? 0) + (byCategory[.shopping] ?? 0)
        let discretionaryRatio = totalIncome > 0 ? discretionary / totalIncome : 0

        // Expense growth rate vs last month
        let lastMonth    = offsetMonth(selectedMonth, by: -1)
        let lastMonthTx  = transactions.filter { $0.month == lastMonth && $0.isExpense }
        let lastExpenses = lastMonthTx.reduce(0) { $0 + $1.amount }
        let growthRate: Double? = lastExpenses > 0
            ? ((totalExpenses - lastExpenses) / lastExpenses) * 100
            : nil

        return FinancialSummary(
            monthlyIncome:      totalIncome,
            monthlyExpenses:    totalExpenses,
            monthlyNet:         netBalance,
            savingsRate:        savingsRate,
            dailyAverage:       dailyAverage,
            byCategory:         byCategory,
            currentBalance:     currentBalance,
            totalSavings:       totalSavings,
            financialStability: stability,
            isOverspending:     totalExpenses > totalIncome && totalIncome > 0,
            discretionaryRatio: discretionaryRatio,
            expenseGrowthRate:  growthRate
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Smart Insights Engine
    // Rule-based — no AI needed. Fast and reliable.
    // ─────────────────────────────────────────────────────────────────────────

    private func buildInsights() -> [SmartInsight] {
        guard let s = summary else { return [] }
        var result: [SmartInsight] = []

        // ── Danger ────────────────────────────────────────────────────────
        if s.isOverspending {
            result.append(SmartInsight(
                type:    .danger,
                title:   "You're overspending",
                message: "Your expenses (\(formatted(s.monthlyExpenses))€) exceed your income (\(formatted(s.monthlyIncome))€) this month.",
                icon:    "exclamationmark.triangle.fill",
                color:   "F87171"
            ))
        }

        if s.financialStability == .risky {
            result.append(SmartInsight(
                type:    .danger,
                title:   "Low emergency fund",
                message: "Your savings cover less than 1 month of expenses. Aim for at least 3 months.",
                icon:    "exclamationmark.shield.fill",
                color:   "F87171"
            ))
        }

        // ── Warnings ──────────────────────────────────────────────────────
        if s.savingsRate < 10 && s.monthlyIncome > 0 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "Low savings rate",
                message: "You're saving \(formatted(s.savingsRate))% of your income. The recommended minimum is 20%.",
                icon:    "arrow.down.circle.fill",
                color:   "FACC15"
            ))
        }

        if s.percentage(for: .food) > 35 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "High food spending",
                message: "Food is \(formatted(s.percentage(for: .food)))% of your expenses this month — above the 35% threshold.",
                icon:    "fork.knife",
                color:   "FACC15"
            ))
        }

        if s.discretionaryRatio > 0.3 && s.monthlyIncome > 0 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "High discretionary spending",
                message: "Entertainment and shopping account for \(formatted(s.discretionaryRatio * 100))% of your income.",
                icon:    "bag.fill",
                color:   "FACC15"
            ))
        }

        if let growth = s.expenseGrowthRate, growth > 20 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "Expenses increased",
                message: "Your spending is up \(formatted(growth))% compared to last month.",
                icon:    "arrow.up.right.circle.fill",
                color:   "FB923C"
            ))
        }

        // Budget exceeded warnings
        for limit in budgetLimits {
            if isBudgetExceeded(for: limit.category) {
                let spent = s.amount(for: limit.category)
                result.append(SmartInsight(
                    type:    .warning,
                    title:   "\(limit.category.rawValue) budget exceeded",
                    message: "You spent \(formatted(spent))€ — \(formatted(spent - limit.limit))€ over your \(formatted(limit.limit))€ budget.",
                    icon:    limit.category.icon,
                    color:   "FB923C"
                ))
            }
        }

        // ── Positive ──────────────────────────────────────────────────────
        if s.savingsRate >= 20 {
            result.append(SmartInsight(
                type:    .positive,
                title:   "Great savings rate",
                message: "You're saving \(formatted(s.savingsRate))% of your income — above the recommended 20%. Keep it up.",
                icon:    "star.fill",
                color:   "10B981"
            ))
        }

        if s.financialStability == .stable {
            result.append(SmartInsight(
                type:    .positive,
                title:   "Solid emergency fund",
                message: "Your savings cover more than 3 months of expenses. You're financially stable.",
                icon:    "shield.fill",
                color:   "10B981"
            ))
        }

        if let growth = s.expenseGrowthRate, growth < -10 {
            result.append(SmartInsight(
                type:    .positive,
                title:   "Spending decreased",
                message: "Your expenses dropped \(formatted(abs(growth)))% from last month. Good discipline.",
                icon:    "arrow.down.right.circle.fill",
                color:   "10B981"
            ))
        }

        // ── Info ──────────────────────────────────────────────────────────
        if s.monthlyIncome == 0 && isCurrentMonth {
            result.append(SmartInsight(
                type:    .info,
                title:   "No income logged",
                message: "Add your income transactions to get accurate savings rate and insights.",
                icon:    "plus.circle.fill",
                color:   "6366F1"
            ))
        }

        if transactions.isEmpty {
            result.append(SmartInsight(
                type:    .info,
                title:   "Start tracking",
                message: "Add your first transaction to see your financial picture.",
                icon:    "plus.circle.fill",
                color:   "6366F1"
            ))
        }

        return result
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - AI Context Builder
    // Packages all data into a structured prompt for the AI chat
    // ─────────────────────────────────────────────────────────────────────────

    private func buildAIContext() -> AIFinancialContext? {
        guard let s       = summary,
              let profile = session.user?.financialProfile,
              let user    = session.user
        else { return nil }

        return AIFinancialContext(
            monthlyIncome:      s.monthlyIncome,
            monthlyExpenses:    s.monthlyExpenses,
            monthlyNet:         s.monthlyNet,
            savingsRate:        s.savingsRate,
            currentBalance:     s.currentBalance,
            totalSavings:       s.totalSavings,
            topCategories:      s.topCategories,
            dailyAverage:       s.dailyAverage,
            stabilityLevel:     s.financialStability,
            isOverspending:     s.isOverspending,
            discretionaryRatio: s.discretionaryRatio,
            shortTermGoal:      profile.shortTermGoal,
            longTermGoal:       profile.longTermGoal,
            hasDebt:            profile.hasDebt,
            debtAmount:         profile.hasDebt ? profile.debtAmount : nil,
            riskTolerance:      profile.riskTolerance,
            knowledgeLevel:     profile.knowledgeLevel
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Monthly Snapshot Persistence
    // Call at end of each month or manually to save current state
    // ─────────────────────────────────────────────────────────────────────────

    func saveCurrentMonthSnapshot() async {
        guard let uid, let s = summary else { return }

        let encodedByCategory: [String: Double] = Dictionary(
            uniqueKeysWithValues: s.byCategory.map { ($0.key.rawValue, $0.value) }
        )

        let snapshot = MonthlySnapshot(
            id:               selectedMonth,
            month:            selectedMonth,
            totalIncome:      s.monthlyIncome,
            totalExpenses:    s.monthlyExpenses,
            netBalance:       s.monthlyNet,
            savingsRate:      s.savingsRate,
            byCategory:       encodedByCategory,
            transactionCount: currentMonthTransactions.count,
            computedAt:       Date()
        )

        do {
            try db.saveMonthlySnapshot(snapshot, uid: uid)
            // Refresh snapshots list
            recentSnapshots = try await db.fetchRecentSnapshots(uid: uid, limit: 6)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Form Helpers
    // ─────────────────────────────────────────────────────────────────────────

    var isFormValid: Bool {
        guard let amount = Double(formAmount) else { return false }
        return amount > 0
    }

    var availableCategories: [TransactionCategory] {
        formType == .expense
            ? TransactionCategory.expenseCategories
            : TransactionCategory.incomeCategories
    }

    func setFormType(_ type: TransactionType) {
        formType     = type
        formCategory = type == .expense ? .food : .salary
    }

    func clearForm() {
        formType        = .expense
        formAmount      = ""
        formCategory    = .food
        formNote        = ""
        formDate        = Date()
        formIsRecurring = false
    }

    func clearError() {
        errorMessage = nil
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Utilities
    // ─────────────────────────────────────────────────────────────────────────

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func offsetMonth(_ month: String, by offset: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date    = formatter.date(from: month),
              let newDate = Calendar.current.date(byAdding: .month, value: offset, to: date)
        else { return month }
        return formatter.string(from: newDate)
    }

    static func currentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    deinit {
        streamTask?.cancel()
    }
}