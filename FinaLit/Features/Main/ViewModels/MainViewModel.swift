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
    struct MonthCloseResult {
        let closedMonth: String
        let rolledToMonth: String
        let recurringCreatedCount: Int
    }

    // MARK: - Raw Data
    var transactions:        [Transaction]       = []
    var recurringTemplates:  [RecurringTemplate] = []
    var budgetLimits:        [BudgetLimit]       = []
    var goals:               [FinancialGoal]     = []
    var debtAccounts:        [DebtAccount]       = []
    var recentSnapshots:     [MonthlySnapshot]   = []

    // MARK: - Computed State (rebuilt after every data change)
    private(set) var summary:       FinancialSummary?
    private(set) var insights:      [SmartInsight]   = []
    private(set) var assistantContext: AIAssistantContext?

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
    private var loadedUID: String?
    private var hasLoadedHome = false

    init(db: DatabaseService, session: UserSession) {
        self.db      = db
        self.session = session
    }

    private var uid: String? { session.user?.id }
    private var appLanguage: AppLanguage { session.currentAppLanguage }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        L10n.tr(key, language: appLanguage, arguments: arguments)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Load Home
    // Called once when Main tab appears
    // ─────────────────────────────────────────────────────────────────────────

    func loadHome(force: Bool = false) async {
        guard let uid else { return }
        guard !isLoadingHome else { return }

        if loadedUID != uid {
            resetStateForUserSwitch()
            loadedUID = uid
        }

        if hasLoadedHome && !force {
            return
        }

        isLoadingHome = true
        errorMessage  = nil
        defer { isLoadingHome = false }

        do {
            // Fetch supporting data in parallel
            async let limitsTask    = db.fetchBudgetLimits(uid: uid)
            async let goalsTask     = db.fetchGoals(uid: uid)
            async let debtsTask     = db.fetchDebtAccounts(uid: uid)
            async let snapshotsTask = db.fetchRecentSnapshots(uid: uid, limit: 6)
            async let recurringTask = db.fetchRecurringTemplates(uid: uid)

            let (limits, fetchedGoals, fetchedDebts, snapshots, recurring) =
                try await (limitsTask, goalsTask, debtsTask, snapshotsTask, recurringTask)

            budgetLimits       = limits
            goals              = fetchedGoals
            debtAccounts       = fetchedDebts
            recentSnapshots    = snapshots
            recurringTemplates = recurring

            try seedDebtAccountIfNeeded(uid: uid)

            // Start real-time transaction stream
            startTransactionStream(uid: uid)
            hasLoadedHome = true

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markHomeNeedsRefresh() {
        hasLoadedHome = false
    }

    func handleSessionUserIDChange(_ userID: String?) {
        guard loadedUID != userID else { return }

        streamTask?.cancel()
        streamTask = nil
        resetStateForUserSwitch()
        loadedUID = userID
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
        guard let amount = parseMonetaryInput(formAmount), amount > 0 else {
            errorMessage = localized("Please enter a valid amount.")
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

    func addGoal(title: String, targetAmount: Double, deadline: Date?) async -> String? {
        guard let uid else { return nil }
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
            recalculate()
            return goal.id
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func updateGoalProgress(goal: FinancialGoal, newAmount: Double) async {
        guard let uid, let id = goal.id else { return }
        do {
            let isCompleted = newAmount >= goal.targetAmount
            try db.updateGoalProgress(
                uid: uid,
                goalID: id,
                currentAmount: newAmount,
                isCompleted: isCompleted
            )
            if let index = goals.firstIndex(where: { $0.id == id }) {
                goals[index].currentAmount = newAmount
                goals[index].isCompleted = isCompleted
                if isCompleted {
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

    func contributeToGoal(goal: FinancialGoal, amount: Double) async -> Bool {
        guard let uid, let goalID = goal.id else { return false }

        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
        guard remaining > 0 else {
            errorMessage = localized("This goal is already completed.")
            return false
        }

        guard amount > 0 else {
            errorMessage = localized("Enter a valid contribution amount.")
            return false
        }

        let contribution = min(amount, remaining)
        let newAmount = min(goal.currentAmount + contribution, goal.targetAmount)

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let transaction = Transaction(
                id: nil,
                type: .expense,
                amount: contribution,
                category: .other,
                date: Date(),
                note: "Goal contribution - \(goal.title)",
                isRecurring: false,
                recurringID: nil
            )
            try db.addTransaction(transaction, uid: uid)

            let isCompleted = newAmount >= goal.targetAmount
            try db.updateGoalProgress(
                uid: uid,
                goalID: goalID,
                currentAmount: newAmount,
                isCompleted: isCompleted
            )
            if newAmount >= goal.targetAmount {
                try db.markGoalCompleted(uid: uid, goalID: goalID)
            }

            if let index = goals.firstIndex(where: { $0.id == goalID }) {
                goals[index].currentAmount = newAmount
                goals[index].isCompleted = newAmount >= goals[index].targetAmount
            }

            recalculate()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Debt
    // ─────────────────────────────────────────────────────────────────────────

    func addDebtAccount(
        name: String,
        balance: Double,
        annualInterestRate: Double? = nil,
        minimumMonthlyPayment: Double? = nil
    ) async -> Bool {
        guard let uid else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = localized("Please enter a debt account name.")
            return false
        }
        guard balance > 0 else {
            errorMessage = localized("Please enter a valid debt balance.")
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let account = DebtAccount(
            id: UUID().uuidString,
            name: trimmedName,
            currentBalance: balance,
            annualInterestRate: annualInterestRate,
            minimumMonthlyPayment: minimumMonthlyPayment,
            createdAt: Date(),
            updatedAt: Date(),
            isClosed: false
        )

        do {
            try db.createDebtAccount(account, uid: uid)
            debtAccounts.append(account)
            recalculate()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func payDebt(account: DebtAccount, amount: Double, note: String = "") async -> Bool {
        guard let uid, let debtID = account.id else { return false }
        guard account.currentBalance > 0 else {
            errorMessage = localized("This debt account is already paid.")
            return false
        }
        guard amount > 0 else {
            errorMessage = localized("Enter a valid payment amount.")
            return false
        }

        let payment = min(amount, account.currentBalance)
        let updatedBalance = max(account.currentBalance - payment, 0)
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let transaction = Transaction(
                id: nil,
                type: .expense,
                amount: payment,
                category: .other,
                date: Date(),
                note: normalizedNote.isEmpty ? "Debt payment - \(account.name)" : normalizedNote,
                isRecurring: false,
                recurringID: nil
            )
            try db.addTransaction(transaction, uid: uid)
            try db.updateDebtBalance(uid: uid, debtID: debtID, newBalance: updatedBalance)

            if let index = debtAccounts.firstIndex(where: { $0.id == debtID }) {
                debtAccounts[index].currentBalance = updatedBalance
                debtAccounts[index].updatedAt = Date()
                debtAccounts[index].isClosed = updatedBalance <= 0
            }

            recalculate()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Month Close & Rollover
    // ─────────────────────────────────────────────────────────────────────────

    func closeSelectedMonthAndRollover() async -> MonthCloseResult? {
        guard let uid else { return nil }
        guard let summary else {
            errorMessage = localized("Month data is still loading. Try again in a moment.")
            return nil
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let closingMonth = selectedMonth
            let nextMonth = offsetMonth(closingMonth, by: 1)

            if try await db.isMonthClosed(uid: uid, month: closingMonth) {
                errorMessage = localized("%@ is already closed.", displayMonth(closingMonth))
                return nil
            }

            let snapshot = monthlySnapshot(from: summary, month: closingMonth)
            try db.saveMonthlySnapshot(snapshot, uid: uid)

            let recurringCreated = try await generateRecurringTransactions(for: nextMonth, uid: uid)

            let closeRecord = MonthCloseRecord(
                id: closingMonth,
                month: closingMonth,
                closedAt: Date(),
                rolledToMonth: nextMonth
            )
            try db.markMonthClosed(uid: uid, record: closeRecord)

            recentSnapshots = try await db.fetchRecentSnapshots(uid: uid, limit: 6)

            if nextMonth <= Self.currentMonthString() {
                selectedMonth = nextMonth
            }

            recalculate()
            return MonthCloseResult(
                closedMonth: closingMonth,
                rolledToMonth: nextMonth,
                recurringCreatedCount: recurringCreated
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Budget Limits
    // ─────────────────────────────────────────────────────────────────────────

    func saveBudgetLimits(_ limits: [BudgetLimit]) async {
        guard let uid else { return }
        do {
            try await db.saveBudgetLimits(limits, uid: uid)
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

    var selectedMonthDate: Date {
        monthDate(from: selectedMonth) ?? maximumSelectableMonthDate
    }

    var maximumSelectableMonthDate: Date {
        startOfMonth(for: Date())
    }

    func setSelectedMonth(from date: Date) {
        let normalizedDate = min(startOfMonth(for: date), maximumSelectableMonthDate)
        let normalizedMonth = monthString(from: normalizedDate)
        guard normalizedMonth != selectedMonth else { return }
        selectedMonth = normalizedMonth
        recalculate()
    }

    var isCurrentMonth: Bool {
        selectedMonth == Self.currentMonthString()
    }

    var selectedMonthDisplay: String {
        displayMonth(selectedMonth)
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

    var activeDebtAccounts: [DebtAccount] {
        debtAccounts.filter { !$0.isClosed && $0.currentBalance > 0 }
    }

    var totalDebtBalance: Double {
        activeDebtAccounts.reduce(0) { $0 + $1.currentBalance }
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
        assistantContext = buildAssistantContext()
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
                message: "Your expenses (\(formatCurrency(s.monthlyExpenses))) exceed your income (\(formatCurrency(s.monthlyIncome))) this month.",
                icon:    "exclamationmark.triangle.fill",
                tone:    .danger
            ))
        }

        if s.financialStability == .risky {
            result.append(SmartInsight(
                type:    .danger,
                title:   "Low emergency fund",
                message: "Your savings cover less than 1 month of expenses. Aim for at least 3 months.",
                icon:    "exclamationmark.shield.fill",
                tone:    .danger
            ))
        }

        // ── Warnings ──────────────────────────────────────────────────────
        if s.savingsRate < 10 && s.monthlyIncome > 0 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "Low savings rate",
                message: "You're saving \(formatted(s.savingsRate))% of your income. The recommended minimum is 20%.",
                icon:    "arrow.down.circle.fill",
                tone:    .warning
            ))
        }

        if s.percentage(for: .food) > 35 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "High food spending",
                message: "Food is \(formatted(s.percentage(for: .food)))% of your expenses this month — above the 35% threshold.",
                icon:    "fork.knife",
                tone:    .warning
            ))
        }

        if s.discretionaryRatio > 0.3 && s.monthlyIncome > 0 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "High discretionary spending",
                message: "Entertainment and shopping account for \(formatted(s.discretionaryRatio * 100))% of your income.",
                icon:    "bag.fill",
                tone:    .warning
            ))
        }

        if let growth = s.expenseGrowthRate, growth > 20 {
            result.append(SmartInsight(
                type:    .warning,
                title:   "Expenses increased",
                message: "Your spending is up \(formatted(growth))% compared to last month.",
                icon:    "arrow.up.right.circle.fill",
                tone:    .orange
            ))
        }

        // Budget exceeded warnings
        for limit in budgetLimits {
            if isBudgetExceeded(for: limit.category) {
                let spent = s.amount(for: limit.category)
                result.append(SmartInsight(
                    type:    .warning,
                    title:   "\(limit.category.rawValue) budget exceeded",
                    message: "You spent \(formatCurrency(spent)) — \(formatCurrency(spent - limit.limit)) over your \(formatCurrency(limit.limit)) budget.",
                    icon:    limit.category.icon,
                    tone:    .orange
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
                tone:    .success
            ))
        }

        if s.financialStability == .stable {
            result.append(SmartInsight(
                type:    .positive,
                title:   "Solid emergency fund",
                message: "Your savings cover more than 3 months of expenses. You're financially stable.",
                icon:    "shield.fill",
                tone:    .success
            ))
        }

        if let growth = s.expenseGrowthRate, growth < -10 {
            result.append(SmartInsight(
                type:    .positive,
                title:   "Spending decreased",
                message: "Your expenses dropped \(formatted(abs(growth)))% from last month. Good discipline.",
                icon:    "arrow.down.right.circle.fill",
                tone:    .success
            ))
        }

        // ── Info ──────────────────────────────────────────────────────────
        if s.monthlyIncome == 0 && isCurrentMonth {
            result.append(SmartInsight(
                type:    .info,
                title:   "No income logged",
                message: "Add your income transactions to get accurate savings rate and insights.",
                icon:    "plus.circle.fill",
                tone:    .info
            ))
        }

        if transactions.isEmpty {
            result.append(SmartInsight(
                type:    .info,
                title:   "Start tracking",
                message: "Add your first transaction to see your financial picture.",
                icon:    "plus.circle.fill",
                tone:    .info
            ))
        }

        return result
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - AI Context Builder
    // Packages all data into a structured prompt for the AI chat
    // ─────────────────────────────────────────────────────────────────────────

    private func buildAssistantContext() -> AIAssistantContext? {
        guard let s       = summary,
              let profile = session.user?.financialProfile
        else { return nil }

        let onboardingDebt = profile.hasDebt ? (profile.debtAmount ?? 0) : 0
        let effectiveDebt = debtAccounts.isEmpty ? onboardingDebt : totalDebtBalance
        let hasDebt = effectiveDebt > 0
        let budgetOverages = buildBudgetOverages(from: s)
        let activeGoalSummaries = buildActiveGoalSummaries()
        let keyInsights = insights
            .prefix(3)
            .map { "\($0.title): \($0.message)" }

        return AIAssistantContext(
            selectedMonth:       selectedMonth,
            selectedMonthDisplay: selectedMonthDisplay,
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
            hasDebt:            hasDebt,
            debtAmount:         hasDebt ? effectiveDebt : nil,
            riskTolerance:      profile.riskTolerance,
            knowledgeLevel:     profile.knowledgeLevel,
            budgetOverages:     budgetOverages,
            keyInsights:        keyInsights,
            activeGoals:        activeGoalSummaries,
            debtSummary:        debtSummary(totalDebt: effectiveDebt, hasDebt: hasDebt)
        )
    }

    private func buildBudgetOverages(from summary: FinancialSummary) -> [AssistantBudgetOverage] {
        budgetLimits
            .compactMap { limit in
                let spent = summary.amount(for: limit.category)
                guard spent > limit.limit else { return nil }

                return AssistantBudgetOverage(
                    category: limit.category,
                    spent: spent,
                    limit: limit.limit
                )
            }
            .sorted { $0.overAmount > $1.overAmount }
    }

    private func buildActiveGoalSummaries() -> [AssistantGoalProgress] {
        activeGoals
            .sorted { lhs, rhs in
                switch (lhs.deadline, rhs.deadline) {
                case let (left?, right?):
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return lhs.createdAt < rhs.createdAt
                }
            }
            .prefix(3)
            .map { goal in
                AssistantGoalProgress(
                    title: goal.title,
                    currentAmount: goal.currentAmount,
                    targetAmount: goal.targetAmount,
                    progressRatio: min(goal.progressPercentage / 100, 1),
                    deadlineText: formattedGoalDeadline(goal.deadline)
                )
            }
    }

    private func debtSummary(totalDebt: Double, hasDebt: Bool) -> String {
        guard hasDebt else { return "No active debt." }

        let accountCount = activeDebtAccounts.count
        if accountCount > 0 {
            let noun = accountCount == 1 ? "account" : "accounts"
            return "\(accountCount) active debt \(noun), total \(formatCurrency(totalDebt))."
        }

        return "Debt total: \(formatCurrency(totalDebt))."
    }

    private func formattedGoalDeadline(_ deadline: Date?) -> String? {
        guard let deadline else { return nil }

        let formatter = DateFormatter()
        formatter.locale = AppRegion.locale
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: deadline)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Monthly Snapshot Persistence
    // Call at end of each month or manually to save current state
    // ─────────────────────────────────────────────────────────────────────────

    func saveCurrentMonthSnapshot() async {
        guard let uid, let s = summary else { return }
        let snapshot = monthlySnapshot(from: s, month: selectedMonth)

        do {
            try db.saveMonthlySnapshot(snapshot, uid: uid)
            // Refresh snapshots list
            recentSnapshots = try await db.fetchRecentSnapshots(uid: uid, limit: 6)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func seedDebtAccountIfNeeded(uid: String) throws {
        guard debtAccounts.isEmpty,
              let profile = session.user?.financialProfile,
              profile.hasDebt,
              let debtAmount = profile.debtAmount,
              debtAmount > 0 else { return }

        let account = DebtAccount(
            id: UUID().uuidString,
            name: "Primary Debt",
            currentBalance: debtAmount,
            annualInterestRate: nil,
            minimumMonthlyPayment: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isClosed: false
        )

        try db.createDebtAccount(account, uid: uid)
        debtAccounts = [account]
    }

    private func monthlySnapshot(from summary: FinancialSummary, month: String) -> MonthlySnapshot {
        let encodedByCategory: [String: Double] = Dictionary(
            uniqueKeysWithValues: summary.byCategory.map { ($0.key.rawValue, $0.value) }
        )

        let monthTransactionCount = transactions.filter { $0.month == month }.count

        return MonthlySnapshot(
            id:               month,
            month:            month,
            totalIncome:      summary.monthlyIncome,
            totalExpenses:    summary.monthlyExpenses,
            netBalance:       summary.monthlyNet,
            savingsRate:      summary.savingsRate,
            byCategory:       encodedByCategory,
            transactionCount: monthTransactionCount,
            computedAt:       Date()
        )
    }

    private func generateRecurringTransactions(for month: String, uid: String) async throws -> Int {
        guard !recurringTemplates.isEmpty else { return 0 }

        let existing = try await db.fetchTransactions(uid: uid, month: month)
        let existingRecurringIDs = Set(existing.compactMap(\.recurringID))
        var createdCount = 0

        for template in recurringTemplates where template.isActive {
            guard let recurringID = template.id,
                  !existingRecurringIDs.contains(recurringID) else { continue }

            let tx = Transaction(
                id: nil,
                type: template.type,
                amount: template.amount,
                category: template.category,
                date: recurringDate(for: template, targetMonth: month),
                note: template.note,
                isRecurring: true,
                recurringID: recurringID
            )
            try db.addTransaction(tx, uid: uid)
            createdCount += 1
        }

        return createdCount
    }

    private func recurringDate(for template: RecurringTemplate, targetMonth: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let targetMonthDate = formatter.date(from: targetMonth) else { return Date() }

        let calendar = Calendar.current
        let desiredDay = calendar.component(.day, from: template.startDate)
        let maxDay = calendar.range(of: .day, in: .month, for: targetMonthDate)?.count ?? 28

        var components = calendar.dateComponents([.year, .month], from: targetMonthDate)
        components.day = min(desiredDay, maxDay)
        return calendar.date(from: components) ?? targetMonthDate
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Form Helpers
    // ─────────────────────────────────────────────────────────────────────────

    var isFormValid: Bool {
        guard let amount = parseMonetaryInput(formAmount) else { return false }
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
        formDate        = defaultFormDateForSelectedMonth()
        formIsRecurring = false
    }

    func prepareTransactionFormForSelectedMonth() {
        formDate = defaultFormDateForSelectedMonth()
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

    private func displayMonth(_ month: String) -> String {
        guard let date = monthDate(from: month) else { return month }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func monthDate(from month: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month)
    }

    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func defaultFormDateForSelectedMonth() -> Date {
        guard !isCurrentMonth else { return Date() }

        guard let monthDate = monthDate(from: selectedMonth) else { return Date() }

        let calendar = Calendar.current
        let todayDay = calendar.component(.day, from: Date())
        let maxDay = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 28

        var components = calendar.dateComponents([.year, .month], from: monthDate)
        components.day = min(todayDay, maxDay)
        return calendar.date(from: components) ?? monthDate
    }

    private func offsetMonth(_ month: String, by offset: Int) -> String {
        guard let date    = monthDate(from: month),
              let newDate = Calendar.current.date(byAdding: .month, value: offset, to: date)
        else { return month }
        return monthString(from: newDate)
    }

    static func currentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    private func resetStateForUserSwitch() {
        streamTask?.cancel()
        streamTask = nil
        hasLoadedHome = false
        selectedMonth = Self.currentMonthString()
        isLoadingTransactions = false
        isSubmitting = false
        transactions = []
        recurringTemplates = []
        budgetLimits = []
        goals = []
        debtAccounts = []
        recentSnapshots = []
        clearForm()
        summary = nil
        insights = []
        assistantContext = nil
        errorMessage = nil
    }

    deinit {
        streamTask?.cancel()
    }
}
