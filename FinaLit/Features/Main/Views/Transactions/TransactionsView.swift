//
//  TransactionsView.swift
//  FinaLit
//

import SwiftUI

struct TransactionsView: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var filterType: TransactionType? = nil
    @State private var searchText: String = ""

    private struct TransactionDayGroup: Identifiable {
        let dayStart: Date
        let label: String
        let transactions: [Transaction]

        var id: Date { dayStart }
    }

    private var filtered: [Transaction] {
        mainVM.currentMonthTransactions.filter { transaction in
            let typeMatch = filterType == nil || transaction.type == filterType
            let searchMatch = searchText.isEmpty ||
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.rawValue.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }

    private var grouped: [TransactionDayGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"

        let groupedByDay = Dictionary(grouping: filtered) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return groupedByDay
            .map { dayStart, transactions in
                TransactionDayGroup(
                    dayStart: dayStart,
                    label: formatter.string(from: dayStart),
                    transactions: transactions.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.dayStart > $1.dayStart }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    transactionsSummaryHeader

                    if filtered.isEmpty {
                        Text(searchText.isEmpty ? "No transactions" : "No results")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    } else {
                        ForEach(grouped) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.label)
                                    .font(AppTheme.Typography.formLabel)
                                    .foregroundStyle(AppTheme.textSecondary)

                                VStack(spacing: 0) {
                                    ForEach(Array(group.transactions.enumerated()), id: \.offset) { index, transaction in
                                        TransactionRow(transaction: transaction)
                                            .onTapGesture {
                                                coordinator.push(.transactionDetail(transaction.id ?? ""))
                                            }
                                        if index < group.transactions.count - 1 {
                                            Divider()
                                                .overlay(AppTheme.separator)
                                                .padding(.leading, 36)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, 8)
            }
        }
        .navigationTitle(L10n.Main.transactions)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(L10n.Main.searchTransactions))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        filterType = nil
                    } label: {
                        filterMenuLabel(title: "All", isSelected: filterType == nil)
                    }

                    Button {
                        filterType = .expense
                    } label: {
                        filterMenuLabel(title: String(localized: "main.expense"), isSelected: filterType == .expense)
                    }

                    Button {
                        filterType = .income
                    } label: {
                        filterMenuLabel(title: String(localized: "main.income"), isSelected: filterType == .income)
                    }
                } label: {
                    Image(systemName: filterType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .font(AppTheme.Typography.toolbarIcon)
                }
            }
        }
    }

    private var transactionsSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(AppTheme.Typography.badgeIcon)
                Text(mainVM.selectedMonthDisplay)
                    .font(AppTheme.Typography.badge)
            }
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.surfaceSecondary)
            .clipShape(Capsule())

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(formatDisplayCurrency(mainVM.currentMonthIncome.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.success)
                        .monospacedDigit()
                    Text(L10n.Main.income)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(AppTheme.separator)

                VStack(spacing: 2) {
                    Text(formatDisplayCurrency(mainVM.currentMonthExpenses.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.danger)
                        .monospacedDigit()
                    Text(L10n.Main.expenses)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(AppTheme.separator)

                VStack(spacing: 2) {
                    Text("\(mainVM.currentMonthTransactions.count)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(L10n.Main.total)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }

    private func filterMenuLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            if isSelected {
                Spacer(minLength: 8)
                Image(systemName: "checkmark")
                    .font(AppTheme.Typography.compactRowIcon)
            }
        }
    }
}
