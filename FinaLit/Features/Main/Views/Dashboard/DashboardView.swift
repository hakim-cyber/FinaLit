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

                        Spacer(minLength: 96)
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
        .overlay(alignment: .bottomTrailing) {
            Button {
                coordinator.push(.addTransaction, type: .sheet)
            } label: {
                Image(systemName: "plus")
                    .font(AppTheme.Typography.toolbarIcon)
                    .foregroundStyle(AppTheme.inverseText)
                    .frame(width: AppTheme.Metrics.floatingActionSize, height: AppTheme.Metrics.floatingActionSize)
                    .background(AppTheme.accent, in: Circle())
            }
            .shadow(color: AppTheme.accent.opacity(0.18), radius: 10, y: 6)
            .padding(.trailing, AppTheme.Spacing.screen)
            .padding(.bottom, 24)
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
                            .font(AppTheme.Typography.compactRowIcon)
                    }
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
                        .font(AppTheme.Typography.toolbarIcon)
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
            Button(L10n.Main.closeMonthRollover) {
                handleMonthClose()
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Main.thisSavesTheMonthlySnapshotAndCreatesNextmonthRecurringTransactions)
        }
        .alert(L10n.Admin.error, isPresented: isShowingErrorAlert) {
            Button(L10n.Auth.ok) { mainVM.clearError() }
        } message: {
            Text(mainVM.errorMessage ?? "")
        }
        .onDisappear {
            closeMonthToastTask?.cancel()
        }
    }

    private var monthPickerPopover: some View {
        DatePicker(L10n.Main.selectMonth,
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
            return mainVM.debtAccounts.isEmpty ? String(localized: "main.createFirstDebt") : String(localized: "main.addAnotherDebt")
        }
        return "\(formatDisplayCurrency(mainVM.totalDebtBalance)) remaining"
    }

    private var balanceHeroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Main.currentBalance)
                    .font(AppTheme.Typography.heroLabel)
                    .foregroundStyle(AppTheme.textSecondary)

                if let summary = mainVM.summary {
                    Text(formatDisplayCurrency(summary.currentBalance))
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
                    title: summary.financialStability.localizedName,
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
                label: String(localized: "main.income"),
                value: mainVM.summary.map { formatDisplayCurrency($0.monthlyIncome) } ?? "—",
                icon: "arrow.up.circle.fill",
                tone: .success
            )
            StatMiniCard(
                label: String(localized: "main.expense"),
                value: mainVM.summary.map { formatDisplayCurrency($0.monthlyExpenses) } ?? "—",
                icon: "arrow.down.circle.fill",
                tone: .danger
            )
            StatMiniCard(
                label: String(localized: "main.savings"),
                value: mainVM.summary.map { "\(formatAmount($0.savingsRate))%" } ?? "—",
                icon: "chart.line.uptrend.xyaxis",
                tone: mainVM.summary.map { $0.savingsRate >= 20 ? .success : .warning } ?? .slate
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: L10n.Main.actions)

            HStack(spacing: 10) {
                QuickActionCard(
                    title: mainVM.activeDebtAccounts.isEmpty ? String(localized: "main.addDebt") : String(localized: "main.payDebt"),
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
                    title: String(localized: "main.addToGoal"),
                    subtitle: mainVM.activeGoals.isEmpty ? String(localized: "main.createFirstGoal") : String(localized: "main.contributeNow"),
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
                    title: String(localized: "main.closeMonth"),
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
                    AppSectionHeader(title: L10n.Main.insights, actionTitle: L10n.Main.seeAll) {
                        coordinator.push(.insights)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(mainVM.insights.prefix(4)) { insight in
                                InsightChip(insight: insight)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.screen)
                    }
                    .padding(.horizontal, -AppTheme.Spacing.screen)
                }
            }
        }
    }

    private var categoryBreakdown: some View {
        Group {
            if let summary = mainVM.summary, !summary.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    AppSectionHeader(title: L10n.Main.thisMonth, actionTitle: L10n.Main.budget) {
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
                        Button(L10n.Main.viewAllCategories) {
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
            AppSectionHeader(title: "Goals", actionTitle: mainVM.activeGoals.isEmpty ? L10n.Main.newGoal : L10n.Main.seeAll) {
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
            AppSectionHeader(title: L10n.Main.recentTransactions, actionTitle: L10n.Main.allTransactions) {
                coordinator.push(.transactions)
            }

            if mainVM.currentMonthTransactions.isEmpty {
                EmptyTransactionsCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mainVM.currentMonthTransactions.prefix(5).enumerated()), id: \.offset) { index, transaction in
                        TransactionRow(transaction: transaction, horizontalPadding: 12)
                            .onTapGesture {
                                coordinator.push(.transactionDetail(transaction.id ?? ""))
                            }
                        if index < min(mainVM.currentMonthTransactions.count, 5) - 1 {
                            Divider()
                                .overlay(AppTheme.separator)
                                .padding(.leading, 44)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .appSurface(.primary, padding: 0, cornerRadius: AppTheme.CornerRadius.large)
            }
        }
    }
}
