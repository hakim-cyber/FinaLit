//
//  DashboardView.swift
//  FinaLit
//

import SwiftUI

struct DashboardView: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
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

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                label: "Income",
                value: mainVM.summary.map { formatCurrency($0.monthlyIncome) } ?? "—",
                icon: "arrow.up.circle.fill",
                color: "10B981"
            )
            StatMiniCard(
                label: "Expenses",
                value: mainVM.summary.map { formatCurrency($0.monthlyExpenses) } ?? "—",
                icon: "arrow.down.circle.fill",
                color: "F87171"
            )
            StatMiniCard(
                label: "Savings",
                value: mainVM.summary.map { "\(formatAmount($0.savingsRate))%" } ?? "—",
                icon: "chart.line.uptrend.xyaxis",
                color: mainVM.summary.map { $0.savingsRate >= 20 ? "10B981" : "FACC15" } ?? "6B7280"
            )
        }
        .padding(.horizontal, 20)
    }

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
                                category: category,
                                amount: amount,
                                total: summary.monthlyExpenses,
                                limit: mainVM.budgetLimit(for: category)
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
                    ForEach(mainVM.currentMonthTransactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction)
                            .onTapGesture {
                                coordinator.push(.transactionDetail(transaction.id ?? ""))
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
