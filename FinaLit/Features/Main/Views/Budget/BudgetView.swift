//
//  BudgetView.swift
//  FinaLit
//

import SwiftUI

struct BudgetView: View {
    @Environment(MainViewModel.self) private var mainVM
    @State private var editingLimits: [TransactionCategory: String] = [:]
    @State private var isEditing = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(AppTheme.Typography.badgeIcon)
                        Text(mainVM.selectedMonthDisplay)
                            .font(AppTheme.Typography.badge)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.surfacePrimary)
                    .clipShape(Capsule())
                    .padding(.top, 8)

                    HStack {
                        Text(L10n.Main.setMonthlyLimitsPerCategory)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Button(isEditing ? String(localized: "main.save") : String(localized: "main.edit")) {
                            if isEditing {
                                saveLimits()
                            } else {
                                startEditing()
                            }
                            isEditing.toggle()
                        }
                        .font(AppTheme.Typography.bodySemibold)
                        .foregroundStyle(AppTheme.accent)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(TransactionCategory.expenseCategories.enumerated()), id: \.element.rawValue) { index, category in
                            BudgetCategoryCard(
                                category: category,
                                spent: mainVM.summary?.amount(for: category) ?? 0,
                                limit: mainVM.budgetLimit(for: category),
                                isEditing: isEditing,
                                editingText: Binding(
                                    get: { editingLimits[category] ?? "" },
                                    set: { editingLimits[category] = $0 }
                                )
                            )
                            if index < TransactionCategory.expenseCategories.count - 1 {
                                Divider()
                                    .overlay(AppTheme.separator)
                                    .padding(.leading, 36)
                            }
                        }
                    }
                    .appSurface(.primary, padding: 0, cornerRadius: AppTheme.CornerRadius.large)

                    if let summary = mainVM.summary {
                        TotalBudgetCard(
                            spent: summary.monthlyExpenses,
                            totalLimit: mainVM.budgetLimits.reduce(0) { $0 + $1.limit }
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
            }
        }
        .navigationTitle(L10n.Main.budget)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startEditing() {
        for category in TransactionCategory.expenseCategories {
            if let limit = mainVM.budgetLimit(for: category) {
                editingLimits[category] = String(format: "%.0f", limit)
            } else {
                editingLimits[category] = ""
            }
        }
    }

    private func saveLimits() {
        var limits: [BudgetLimit] = []
        for (category, text) in editingLimits {
            if let value = parseMonetaryInput(text), value > 0 {
                limits.append(
                    BudgetLimit(
                        id: UUID().uuidString,
                        category: category,
                        limit: value
                    )
                )
            }
        }
        Task { await mainVM.saveBudgetLimits(limits) }
    }
}
