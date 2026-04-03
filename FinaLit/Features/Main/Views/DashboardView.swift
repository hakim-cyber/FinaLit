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
    @Environment(Coordinator<MainPages>.self)  private var coordinator
    @State private var showPayDebtSheet = false
    @State private var showAddDebtSheet = false
    @State private var showGoalContributionSheet = false
    @State private var showCloseMonthDialog = false
    @State private var closeMonthSuccessMessage: String?
    @State private var closeMonthToastTask: Task<Void, Never>?
    @State private var showMonthPicker = false
    @State private var monthPickerDate = Date()

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if mainVM.isLoadingHome {
                MainLoadingView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
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
                .refreshable {
                    await mainVM.loadHome(force: true)
                }
            }

            if let closeMonthSuccessMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "10B981"))
                            .font(.system(size: 14))
                        Text(closeMonthSuccessMessage)
                            .font(.system(size: 12, weight: .semibold))
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
                                .fill(Color.accentColor)
                                .frame(width: 50, height: 50)
                               
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .glassEffectIfAvailable()
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                    
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    monthPickerDate = mainVM.selectedMonthDate
                    showMonthPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(mainVM.selectedMonthDisplay)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.primary)
                }
                .popover(isPresented: $showMonthPicker, arrowEdge: .top) {
                    monthPickerPopover
                        .presentationCompactAdaptation(.popover)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.settings, type: .fullScreenCover)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.primary)
                }
            }
        }
      
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
            GoalContributionSheet(onAddGoal: {
                showGoalContributionSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    coordinator.push(.addGoal)
                }
            })
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
        .alert("Error", isPresented: isShowingErrorAlert) {
            Button("OK") { mainVM.clearError() }
        } message: {
            Text(mainVM.errorMessage ?? "")
        }
        .onDisappear {
            closeMonthToastTask?.cancel()
        }
    }

    private var monthPickerPopover: some View {
        DatePicker(
            "Select month",
            selection: Binding(
                get: { monthPickerDate },
                set: { newValue in
                    monthPickerDate = newValue
                    mainVM.setSelectedMonth(from: newValue)
                    showMonthPicker = false
                }
            ),
            in: ...mainVM.maximumSelectableMonthDate,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
        .padding(16)
        .frame(width: 320)
    
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { mainVM.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    mainVM.clearError()
                }
            }
        )
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
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))

                if let summary = mainVM.summary {
                    Text(formatCompactCurrency(summary.currentBalance))
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(summary.currentBalance >= 0 ? .white : Color(hex: "F87171"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                        .allowsTightening(true)
                } else {
                    Text("\(AppRegion.currencySymbol) —")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            // Stability badge
            if let summary = mainVM.summary {
                HStack(spacing: 6) {
                    Image(systemName: summary.financialStability.icon)
                        .font(.system(size: 11))
                    Text(summary.financialStability.rawValue)
                        .font(.system(size: 11))
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
                .font(.system(size: 11, weight: .semibold))
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("See all →") {
                            coordinator.push(.insights)
                        }
                        .font(.system(size: 11))
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button("Budget →") {
                            coordinator.push(.budget)
                        }
                        .font(.system(size: 11))
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
                        .font(.system(size: 12))
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                Button(mainVM.activeGoals.isEmpty ? "New goal →" : "See all →") {
                    coordinator.push(mainVM.activeGoals.isEmpty ? .addGoal : .goals)
                }
                .font(.system(size: 11))
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                Button("All transactions →") {
                    coordinator.push(.transactions)
                }
                .font(.system(size: 11))
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(insight.message)
                    .font(.system(size: 10))
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
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(amount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isOverBudget ? Color(hex: "F87171") : .white)
                    if let limit {
                        Text("of \(formatCurrency(limit))")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "4B5563"))
                    } else {
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(.system(size: 10))
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
                            width: progressBarWidth(totalWidth: geo.size.width),
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

    private func progressBarWidth(totalWidth: CGFloat) -> CGFloat {
        if let limit, limit > 0 {
            return min(totalWidth * CGFloat(amount / limit), totalWidth)
        }

        return totalWidth * CGFloat(percentage / 100)
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
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(String(format: "%.0f", goal.progressPercentage))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            HStack {
                Text(formatCurrency(goal.currentAmount))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Text("of \(formatCurrency(goal.targetAmount))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            if let monthlyPaceText {
                Text(monthlyPaceText)
                    .font(.system(size: 10, weight: .semibold))
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
                .font(.system(size: 15))
                .foregroundStyle(.white)

            Text("Create your first goal and start tracking progress from your dashboard.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create your first goal")
                }
                .font(.system(size: 13, weight: .semibold))
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
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Spacer()
            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                .font(.system(size: 14, weight: .semibold))
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
                .font(.system(size: 16))
                .foregroundStyle(.white)
            Text("Tap + to add your first transaction")
                .font(.system(size: 12))
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10))
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

    private func saveDebtAccount() {
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
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT NAME")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. Credit Card", text: $accountName)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CURRENT BALANCE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $balance)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APR % (OPTIONAL)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                            TextField("e.g. 19.9", text: $annualInterestRate)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("MIN PAYMENT (OPTIONAL)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                            TextField("e.g. 50", text: $minimumPayment)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                        }
                    }
                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Add Debt Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveDebtAccount()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || mainVM.isSubmitting)
                }
            }
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
    @State private var showDebtAccountPicker = false

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

    private func submitPayment() {
        guard let account = selectedAccount, let value = parsedAmount else { return }
        Task {
            let paid = await mainVM.payDebt(account: account, amount: value, note: note)
            if paid { dismiss() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    debtAccountSection

                    if mainVM.activeDebtAccounts.isEmpty {
                        Text("Create a debt account first to record a payment.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("Debt payment", text: $note)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Pay Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        submitPayment()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
        .onAppear {
            if selectedDebtID.isEmpty {
                selectedDebtID = mainVM.activeDebtAccounts.first?.id ?? ""
            }
        }
    }

    private var debtAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeDebtAccounts.isEmpty else { return }
                    showDebtAccountPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedAccount?.name ?? "No debt account selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)

                            Text(selectedAccount.map { formatCurrency($0.currentBalance) } ?? "Tap + to create a debt account")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(mainVM.activeDebtAccounts.isEmpty ? Color(hex: "374151") : Color(hex: "9CA3AF"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "111118"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "1F2937"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(mainVM.activeDebtAccounts.isEmpty)
                .popover(isPresented: $showDebtAccountPicker, arrowEdge: .top) {
                    debtAccountPickerPopover
                        .presentationCompactAdaptation(.popover)
                }

                Button {
                    openAddDebt()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "F97316").opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "F97316").opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var debtAccountPickerPopover: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Debt Account")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                ForEach(mainVM.activeDebtAccounts) { account in
                    Button {
                        selectedDebtID = account.id ?? ""
                        showDebtAccountPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)

                                Text(formatCurrency(account.currentBalance))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }

                            Spacer()

                            if account.id == selectedAccount?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "F97316"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: account.id == selectedAccount?.id ? "171724" : "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(hex: account.id == selectedAccount?.id ? "F97316" : "1F2937").opacity(account.id == selectedAccount?.id ? 0.35 : 1),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(Color(hex: "0A0A0F"))
    }
}

// MARK: - Goal Contribution Sheet
struct GoalContributionSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    let onAddGoal: () -> Void
    @State private var selectedGoalID: String = ""
    @State private var amount: String = ""
    @State private var showGoalPicker = false

    init(onAddGoal: @escaping () -> Void = {}) {
        self.onAddGoal = onAddGoal
    }

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

    private func openAddGoal() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAddGoal()
        }
    }

    private func submitContribution() {
        guard let goal = selectedGoal, let value = parsedAmount else { return }
        Task {
            let saved = await mainVM.contributeToGoal(goal: goal, amount: value)
            if saved { dismiss() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    goalSection

                    if mainVM.activeGoals.isEmpty {
                        Text("Create a goal first to add a contribution.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTRIBUTION")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    if let goal = selectedGoal {
                        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
                        Text("Remaining: \(formatCurrency(remaining))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Add to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        submitContribution()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
        .onAppear {
            if selectedGoalID.isEmpty {
                selectedGoalID = mainVM.activeGoals.first?.id ?? ""
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GOAL")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeGoals.isEmpty else { return }
                    showGoalPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedGoal?.title ?? "No goal selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)

                            Text(goalSubtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(mainVM.activeGoals.isEmpty ? Color(hex: "374151") : Color(hex: "9CA3AF"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "111118"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "1F2937"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(mainVM.activeGoals.isEmpty)
                .popover(isPresented: $showGoalPicker, arrowEdge: .top) {
                    goalPickerPopover
                        .presentationCompactAdaptation(.popover)
                }

                Button {
                    openAddGoal()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "6366F1").opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "6366F1").opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var goalSubtitle: String {
        guard let goal = selectedGoal else { return "Tap + to create a goal" }
        return "\(Int(goal.progressPercentage.rounded()))% funded • \(formatCurrency(max(goal.targetAmount - goal.currentAmount, 0))) left"
    }

    private var goalPickerPopover: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Goal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                ForEach(mainVM.activeGoals) { goal in
                    Button {
                        selectedGoalID = goal.id ?? ""
                        showGoalPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)

                                Text("\(Int(goal.progressPercentage.rounded()))% funded • \(formatCurrency(max(goal.targetAmount - goal.currentAmount, 0))) left")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }

                            Spacer()

                            if goal.id == selectedGoal?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "6366F1"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: goal.id == selectedGoal?.id ? "171724" : "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(hex: goal.id == selectedGoal?.id ? "6366F1" : "1F2937").opacity(goal.id == selectedGoal?.id ? 0.35 : 1),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(Color(hex: "0A0A0F"))
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
