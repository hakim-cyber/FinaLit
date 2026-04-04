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
            AppTheme.background.ignoresSafeArea()

            if mainVM.isLoadingHome {
                MainLoadingView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                        balanceHeroCard
                        statsRow
                        quickActions
                        insightsStrip
                        categoryBreakdown
                        goalsPreview
                        recentTransactions

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
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
                            .foregroundStyle(AppTheme.success)
                            .font(.system(size: 14))
                        Text(closeMonthSuccessMessage)
                            .font(AppTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                    }
                    .appSurface(.tinted(.success), padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    coordinator.push(.addTransaction, type: .sheet)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.inverseText)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.accent, in: Circle())
                }
                .shadow(color: AppTheme.accent.opacity(0.18), radius: 10, y: 6)
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(AppTheme.background.opacity(0.94))
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
                    .foregroundStyle(AppTheme.textPrimary)
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
                        .foregroundStyle(AppTheme.textPrimary)
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
                Text("Current balance")
                    .font(AppTheme.Typography.heroLabel)
                    .foregroundStyle(AppTheme.textSecondary)

                if let summary = mainVM.summary {
                    Text(formatPrimaryCurrency(summary.currentBalance))
                        .font(AppTheme.Typography.heroAmount)
                        .foregroundStyle(summary.currentBalance >= 0 ? AppTheme.textPrimary : AppTheme.danger)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .allowsTightening(true)
                } else {
                    Text("\(AppRegion.currencySymbol) —")
                        .font(AppTheme.Typography.heroAmount)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if let summary = mainVM.summary {
                AppToneBadge(
                    title: summary.financialStability.rawValue,
                    systemImage: summary.financialStability.icon,
                    tone: summary.financialStability.tone
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.elevated, padding: 22, cornerRadius: AppTheme.CornerRadius.hero)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatMiniCard(
                label: "Income",
                value: mainVM.summary.map { formatCurrency($0.monthlyIncome) } ?? "—",
                icon: "arrow.up.circle.fill",
                tone: .success
            )
            StatMiniCard(
                label: "Expenses",
                value: mainVM.summary.map { formatCurrency($0.monthlyExpenses) } ?? "—",
                icon: "arrow.down.circle.fill",
                tone: .danger
            )
            StatMiniCard(
                label: "Savings",
                value: mainVM.summary.map { "\(formatAmount($0.savingsRate))%" } ?? "—",
                icon: "chart.line.uptrend.xyaxis",
                tone: mainVM.summary.map { $0.savingsRate >= 20 ? .success : .warning } ?? .slate
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Actions")

            HStack(spacing: 10) {
                QuickActionCard(
                    title: mainVM.activeDebtAccounts.isEmpty ? "Add Debt" : "Pay Debt",
                    subtitle: debtQuickActionSubtitle,
                    icon: "creditcard.fill",
                    tone: .orange,
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
                    tone: .accent,
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
                    tone: .blue,
                    isDisabled: mainVM.isSubmitting
                ) {
                    showCloseMonthDialog = true
                }
            }
        }
    }

    private var insightsStrip: some View {
        Group {
            if !mainVM.insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader(title: "Insights", actionTitle: "See all") {
                        coordinator.push(.insights)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(mainVM.insights.prefix(4)) { insight in
                                InsightChip(insight: insight)
                            }
                        }
                    }
                }
            }
        }
    }

    private var categoryBreakdown: some View {
        Group {
            if let summary = mainVM.summary, !summary.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    AppSectionHeader(title: "This month", actionTitle: "Budget") {
                        coordinator.push(.budget)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(summary.topCategories.enumerated()), id: \.element.0) { index, entry in
                            CategoryRow(
                                category: entry.0,
                                amount: entry.1,
                                total: summary.monthlyExpenses,
                                limit: mainVM.budgetLimit(for: entry.0)
                            )
                            if index < summary.topCategories.count - 1 {
                                Divider()
                                    .overlay(AppTheme.separator)
                            }
                        }
                    }
                    .appSurface(.primary, padding: 14, cornerRadius: AppTheme.CornerRadius.large)

                    if summary.byCategory.count > 3 {
                        Button("View all categories") {
                            coordinator.push(.budget)
                        }
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var goalsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Goals", actionTitle: mainVM.activeGoals.isEmpty ? "New goal" : "See all") {
                coordinator.push(mainVM.activeGoals.isEmpty ? .addGoal : .goals)
            }

            if mainVM.activeGoals.isEmpty {
                EmptyGoalsPreviewCard {
                    coordinator.push(.addGoal)
                }
            } else {
                ForEach(mainVM.activeGoals.prefix(2)) { goal in
                    GoalPreviewCard(goal: goal)
                        .onTapGesture {
                            coordinator.push(.goalDetail(goal.id ?? ""))
                        }
                }
            }
        }
    }

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Recent transactions", actionTitle: "All transactions") {
                coordinator.push(.transactions)
            }

            if mainVM.currentMonthTransactions.isEmpty {
                EmptyTransactionsCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mainVM.currentMonthTransactions.prefix(5).enumerated()), id: \.offset) { index, transaction in
                        TransactionRow(transaction: transaction)
                            .onTapGesture {
                                coordinator.push(.transactionDetail(transaction.id ?? ""))
                            }
                        if index < min(mainVM.currentMonthTransactions.count, 5) - 1 {
                            Divider()
                                .overlay(AppTheme.separator)
                                .padding(.leading, 62)
                        }
                    }
                }
                .appSurface(.primary, padding: 0, cornerRadius: AppTheme.CornerRadius.large)
            }
        }
    }
}
