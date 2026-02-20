//
//  DashboardView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// DashboardView.swift
// Features/Main/Views/

import SwiftUI

struct DashboardView: View {
    @Environment(MainViewModel.self)           private var mainVM
    @Environment(UserSession.self)             private var session
    @Environment(Coordinator<MainPages>.self)  private var coordinator
    @State private var showPayDebtSheet = false
    @State private var showAddDebtSheet = false
    @State private var showGoalContributionSheet = false
    @State private var showCloseMonthDialog = false
    @State private var closeMonthSuccessMessage: String?
    @State private var closeMonthToastTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if mainVM.isLoadingHome {
                MainLoadingView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        headerSection
                        balanceHeroCard
                        statsRow
                        quickActions
                        insightsStrip
                        categoryBreakdown
                        goalsPreview
                        recentTransactions

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }

            if let closeMonthSuccessMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "10B981"))
                            .font(.system(size: 14))
                        Text(closeMonthSuccessMessage)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "111118"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "10B981").opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── FAB: Add Transaction ───────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                       
                        coordinator.push(.addTransaction, type: .sheet)

                        
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                                .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 12, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await mainVM.loadHome() }
        .sheet(isPresented: $showPayDebtSheet) {
            PayDebtSheet(onAddDebt: {
                showPayDebtSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showAddDebtSheet = true
                }
            })
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddDebtSheet) {
            AddDebtSheet()
                .presentationDetents([.height(500)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGoalContributionSheet) {
            GoalContributionSheet()
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Close this month?", isPresented: $showCloseMonthDialog, titleVisibility: .visible) {
            Button("Close Month & Rollover") {
                handleMonthClose()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This saves the monthly snapshot and creates next-month recurring transactions.")
        }
        .alert("Error", isPresented: .constant(mainVM.errorMessage != nil)) {
            Button("OK") { mainVM.clearError() }
        } message: {
            Text(mainVM.errorMessage ?? "")
        }
        .onDisappear {
            closeMonthToastTask?.cancel()
        }
    }

    private func handleMonthClose() {
        Task { @MainActor in
            guard let result = await mainVM.closeSelectedMonthAndRollover() else { return }
            let closed = formatMonth(result.closedMonth)
            let rolled = formatMonth(result.rolledToMonth)
            let recurringCount = result.recurringCreatedCount
            let recurringText = recurringCount == 1
                ? "1 recurring item added for \(rolled)."
                : "\(recurringCount) recurring items added for \(rolled)."

            let message = "\(closed) closed. \(recurringText)"
            withAnimation(.easeInOut(duration: 0.2)) {
                closeMonthSuccessMessage = message
            }

            closeMonthToastTask?.cancel()
            closeMonthToastTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        closeMonthSuccessMessage = nil
                    }
                }
            }
        }
    }

    private func formatMonth(_ month: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: month) else { return month }
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(session.user?.name.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(.white)
            }
            Spacer()
            // Month navigator
            MonthNavigator()
        }
        .padding(.horizontal, 20)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "good morning"
        case 12..<17: return "good afternoon"
        default:      return "good evening"
        }
    }

    private var debtQuickActionSubtitle: String {
        if mainVM.activeDebtAccounts.isEmpty {
            return mainVM.debtAccounts.isEmpty ? "Create first debt" : "Add another debt"
        }
        return "\(formatCurrency(mainVM.totalDebtBalance)) remaining"
    }

    // MARK: - Balance Hero Card
    private var balanceHeroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CURRENT BALANCE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))

                if let summary = mainVM.summary {
                    Text(formatCurrency(summary.currentBalance))
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundStyle(summary.currentBalance >= 0 ? .white : Color(hex: "F87171"))
                } else {
                    Text("\(AppRegion.currencySymbol) —")
                        .font(.system(size: 42, weight: .light, design: .serif))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            // Stability badge
            if let summary = mainVM.summary {
                HStack(spacing: 6) {
                    Image(systemName: summary.financialStability.icon)
                        .font(.system(size: 11))
                    Text(summary.financialStability.rawValue)
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundStyle(Color(hex: summary.financialStability.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: summary.financialStability.color).opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "111118"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Row (3 cards)
    private var statsRow: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                label:  "Income",
                value:  mainVM.summary.map { formatCurrency($0.monthlyIncome) } ?? "—",
                icon:   "arrow.up.circle.fill",
                color:  "10B981"
            )
            StatMiniCard(
                label:  "Expenses",
                value:  mainVM.summary.map { formatCurrency($0.monthlyExpenses) } ?? "—",
                icon:   "arrow.down.circle.fill",
                color:  "F87171"
            )
            StatMiniCard(
                label:  "Savings",
                value:  mainVM.summary.map { "\(formatAmount($0.savingsRate))%" } ?? "—",
                icon:   "chart.line.uptrend.xyaxis",
                color:  mainVM.summary.map { $0.savingsRate >= 20 ? "10B981" : "FACC15" } ?? "6B7280"
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                QuickActionCard(
                    title: mainVM.activeDebtAccounts.isEmpty ? "Add Debt" : "Pay Debt",
                    subtitle: debtQuickActionSubtitle,
                    icon: "creditcard.fill",
                    colorHex: "F97316",
                    isDisabled: mainVM.isSubmitting
                ) {
                    if mainVM.activeDebtAccounts.isEmpty {
                        showAddDebtSheet = true
                    } else {
                        showPayDebtSheet = true
                    }
                }

                QuickActionCard(
                    title: "Add to Goal",
                    subtitle: mainVM.activeGoals.isEmpty ? "Create first goal" : "Contribute now",
                    icon: "target",
                    colorHex: "10B981",
                    isDisabled: mainVM.isSubmitting
                ) {
                    if mainVM.activeGoals.isEmpty {
                        coordinator.push(.addGoal)
                    } else {
                        showGoalContributionSheet = true
                    }
                }

                QuickActionCard(
                    title: "Close Month",
                    subtitle: mainVM.selectedMonthDisplay,
                    icon: "calendar.badge.checkmark",
                    colorHex: "6366F1",
                    isDisabled: mainVM.isSubmitting
                ) {
                    showCloseMonthDialog = true
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Insights Strip
    private var insightsStrip: some View {
        Group {
            if !mainVM.insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("INSIGHTS")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("See all →") {
                            coordinator.push(.insights)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(mainVM.insights.prefix(4)) { insight in
                                InsightChip(insight: insight)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        Group {
            if let summary = mainVM.summary, !summary.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("THIS MONTH")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("Budget →") {
                            coordinator.push(.budget)
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        ForEach(summary.topCategories, id: \.0) { category, amount in
                            CategoryRow(
                                category:   category,
                                amount:     amount,
                                total:      summary.monthlyExpenses,
                                limit:      mainVM.budgetLimit(for: category)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    if summary.byCategory.count > 3 {
                        Button("View all categories →") {
                            coordinator.push(.budget)
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Goals Preview
    private var goalsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GOALS")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                Button(mainVM.activeGoals.isEmpty ? "New goal →" : "See all →") {
                    coordinator.push(mainVM.activeGoals.isEmpty ? .addGoal : .goals)
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(hex: "6366F1"))
            }
            .padding(.horizontal, 20)

            if mainVM.activeGoals.isEmpty {
                EmptyGoalsPreviewCard {
                    coordinator.push(.addGoal)
                }
                .padding(.horizontal, 20)
            } else {
                ForEach(mainVM.activeGoals.prefix(2)) { goal in
                    GoalPreviewCard(goal: goal)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            coordinator.push(.goalDetail(goal.id ?? ""))
                        }
                }
            }
        }
    }

    // MARK: - Recent Transactions
    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                Button("All transactions →") {
                    coordinator.push(.transactions)
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(hex: "6366F1"))
            }
            .padding(.horizontal, 20)

            if mainVM.currentMonthTransactions.isEmpty {
                EmptyTransactionsCard()
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(mainVM.currentMonthTransactions.prefix(5)) { tx in
                        TransactionRow(transaction: tx)
                            .onTapGesture {
                                coordinator.push(.transactionDetail(tx.id ?? ""))
                            }
                    }
                }
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Month Navigator
struct MonthNavigator: View {
    @Environment(MainViewModel.self) private var mainVM

    var body: some View {
        HStack(spacing: 12) {
            Button {
                mainVM.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
            }

            Text(mainVM.selectedMonthDisplay)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .frame(minWidth: 80)

            Button {
                mainVM.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mainVM.isCurrentMonth ? Color(hex: "1F2937") : Color(hex: "6B7280"))
            }
            .disabled(mainVM.isCurrentMonth)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let label: String
    let value: String
    let icon:  String
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// MARK: - Insight Chip
struct InsightChip: View {
    let insight: SmartInsight

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: insight.color))
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(insight.message)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: insight.color).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: TransactionCategory
    let amount:   Double
    let total:    Double
    let limit:    Double?

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }

    private var isOverBudget: Bool {
        guard let limit else { return false }
        return amount > limit
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: category.color))
                        .frame(width: 20)
                    Text(category.rawValue)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(amount))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isOverBudget ? Color(hex: "F87171") : .white)
                    if let limit {
                        Text("of \(formatCurrency(limit))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                    } else {
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isOverBudget ? Color(hex: "F87171") : Color(hex: category.color))
                        .frame(
                            width: limit != nil
                                ? min(geo.size.width * CGFloat(amount / limit!), geo.size.width)
                                : geo.size.width * CGFloat(percentage / 100),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isOverBudget ? Color(hex: "F87171").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Goal Preview Card
struct GoalPreviewCard: View {
    let goal: FinancialGoal

    private var remainingAmount: Double {
        max(goal.targetAmount - goal.currentAmount, 0)
    }

    private var monthsUntilDeadline: Int? {
        guard let deadline = goal.deadline else { return nil }
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: Date())
        let toDate = calendar.startOfDay(for: deadline)
        return calendar.dateComponents([.month], from: fromDate, to: toDate).month
    }

    private var monthlyPaceText: String? {
        guard remainingAmount > 0, let monthsUntilDeadline else { return nil }
        guard monthsUntilDeadline >= 0 else { return "Deadline passed" }

        let neededPerMonth = remainingAmount / Double(max(monthsUntilDeadline, 1))
        return "Need \(formatCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return Color(hex: "10B981") }
        return monthsUntilDeadline < 0 ? Color(hex: "F87171") : Color(hex: "10B981")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(String(format: "%.0f", goal.progressPercentage))%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            HStack {
                Text(formatCurrency(goal.currentAmount))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Text("of \(formatCurrency(goal.targetAmount))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            if let monthlyPaceText {
                Text(monthlyPaceText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(monthlyPaceColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: geo.size.width * CGFloat(goal.progressPercentage / 100),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

struct EmptyGoalsPreviewCard: View {
    let onCreateGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No active goals yet")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(.white)

            Text("Create your first goal and start tracking progress from your dashboard.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "6B7280"))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create your first goal")
                }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "10B981").opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1F2937"), lineWidth: 1))
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: transaction.category.color).opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: transaction.category.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Spacer()
            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(transaction.isIncome ? Color(hex: "10B981") : .white)
        }
        .padding(12)
    }
}

// MARK: - Empty State
struct EmptyTransactionsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("💸")
                .font(.system(size: 36))
            Text("No transactions yet")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(.white)
            Text("Tap + to add your first transaction")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colorHex: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: colorHex))

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: colorHex).opacity(0.25), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}

// MARK: - Add Debt Sheet
struct AddDebtSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    @State private var accountName: String = ""
    @State private var balance: String = ""
    @State private var annualInterestRate: String = ""
    @State private var minimumPayment: String = ""

    private var parsedBalance: Double? {
        parseMonetaryInput(balance)
    }

    private var parsedAPR: Double? {
        parseMonetaryInput(annualInterestRate)
    }

    private var parsedMinimumPayment: Double? {
        parseMonetaryInput(minimumPayment)
    }

    private var normalizedAPR: Double? {
        guard !annualInterestRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let parsedAPR, parsedAPR >= 0 else { return nil }
        return min(parsedAPR, 100)
    }

    private var normalizedMinimumPayment: Double? {
        guard !minimumPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let parsedMinimumPayment, parsedMinimumPayment > 0 else { return nil }
        return parsedMinimumPayment
    }

    private var isValid: Bool {
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (parsedBalance ?? 0) > 0
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Add Debt Account")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ACCOUNT NAME")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                    TextField("e.g. Credit Card", text: $accountName)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("CURRENT BALANCE")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                    TextField("0", text: $balance)
                        .font(.system(size: 24, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                        .keyboardType(.decimalPad)
                        .tint(Color(hex: "6366F1"))
                        .padding(.vertical, 6)
                    Divider().background(Color(hex: "1F2937"))
                }

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("APR % (OPTIONAL)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. 19.9", text: $annualInterestRate)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MIN PAYMENT (OPTIONAL)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. 50", text: $minimumPayment)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }
                }

                Spacer(minLength: 4)

                Button {
                    guard let value = parsedBalance else { return }
                    Task {
                        let saved = await mainVM.addDebtAccount(
                            name: accountName,
                            balance: value,
                            annualInterestRate: normalizedAPR,
                            minimumMonthlyPayment: normalizedMinimumPayment
                        )
                        if saved { dismiss() }
                    }
                } label: {
                    Text("Save Debt Account")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isValid
                                ? LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid || mainVM.isSubmitting)
            }
            .padding(20)
        }
    }
}

// MARK: - Pay Debt Sheet
struct PayDebtSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    let onAddDebt: () -> Void
    @State private var selectedDebtID: String = ""
    @State private var amount: String = ""
    @State private var note: String = ""

    init(onAddDebt: @escaping () -> Void = {}) {
        self.onAddDebt = onAddDebt
    }

    private var selectedAccount: DebtAccount? {
        mainVM.activeDebtAccounts.first(where: { $0.id == selectedDebtID }) ?? mainVM.activeDebtAccounts.first
    }

    private var parsedAmount: Double? {
        parseMonetaryInput(amount)
    }

    private var isValid: Bool {
        guard let value = parsedAmount, value > 0, selectedAccount != nil else { return false }
        return true
    }

    private func openAddDebt() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAddDebt()
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Pay Debt")
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Add Debt") {
                        openAddDebt()
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "F97316"))
                }

                if mainVM.activeDebtAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No active debt accounts.")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color(hex: "6B7280"))

                        Button {
                            openAddDebt()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create debt account")
                            }
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: "F97316").opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Picker("Debt Account", selection: $selectedDebtID) {
                            ForEach(mainVM.activeDebtAccounts) { account in
                                Text("\(account.name) - \(formatCurrency(account.currentBalance))")
                                    .tag(account.id ?? "")
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("Debt payment", text: $note)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }
                }

                Spacer(minLength: 4)

                Button {
                    guard let account = selectedAccount, let value = parsedAmount else { return }
                    Task {
                        let paid = await mainVM.payDebt(account: account, amount: value, note: note)
                        if paid { dismiss() }
                    }
                } label: {
                    Text("Confirm Payment")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isValid
                                ? LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid || mainVM.isSubmitting)
            }
            .padding(20)
        }
        .onAppear {
            if selectedDebtID.isEmpty {
                selectedDebtID = mainVM.activeDebtAccounts.first?.id ?? ""
            }
        }
    }
}

// MARK: - Goal Contribution Sheet
struct GoalContributionSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoalID: String = ""
    @State private var amount: String = ""

    private var selectedGoal: FinancialGoal? {
        mainVM.activeGoals.first(where: { $0.id == selectedGoalID }) ?? mainVM.activeGoals.first
    }

    private var parsedAmount: Double? {
        parseMonetaryInput(amount)
    }

    private var isValid: Bool {
        guard let value = parsedAmount, value > 0, selectedGoal != nil else { return false }
        return true
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Goal")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                if mainVM.activeGoals.isEmpty {
                    Text("No active goals to contribute to.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(hex: "6B7280"))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GOAL")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Picker("Goal", selection: $selectedGoalID) {
                            ForEach(mainVM.activeGoals) { goal in
                                Text("\(goal.title) - \(String(format: "%.0f", goal.progressPercentage))%")
                                    .tag(goal.id ?? "")
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTRIBUTION")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    if let goal = selectedGoal {
                        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
                        Text("Remaining: \(formatCurrency(remaining))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                }

                Spacer(minLength: 4)

                Button {
                    guard let goal = selectedGoal, let value = parsedAmount else { return }
                    Task {
                        let saved = await mainVM.contributeToGoal(goal: goal, amount: value)
                        if saved { dismiss() }
                    }
                } label: {
                    Text("Contribute")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isValid
                                ? LinearGradient(colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                                 startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isValid || mainVM.isSubmitting)
            }
            .padding(20)
        }
        .onAppear {
            if selectedGoalID.isEmpty {
                selectedGoalID = mainVM.activeGoals.first?.id ?? ""
            }
        }
    }
}

struct MainLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            ProgressView()
                .tint(Color(hex: "6366F1"))
                .scaleEffect(1.3)
        }
    }
}
