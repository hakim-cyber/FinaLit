//
//  BudgetCategoryCard.swift
//  FinaLit
//

import SwiftUI

struct BudgetCategoryCard: View {
    let category: TransactionCategory
    let spent: Double
    let limit: Double?
    let isEditing: Bool
    @Binding var editingText: String

    private var usage: Double {
        guard let limit, limit > 0 else { return 0 }
        return min(spent / limit, 1)
    }

    private var isOver: Bool {
        guard let limit else { return false }
        return spent > limit
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(AppTheme.Typography.rowIcon)
                    .foregroundStyle(AppTheme.tint(for: category.tone))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(AppTheme.Typography.bodySemibold)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(String(localized: "main.spentPrefix") + " " + formatDisplayCurrency(spent))
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                if isEditing {
                    HStack(spacing: 4) {
                        Text(AppRegion.currencySymbol)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField(L10n.Main.limit, text: $editingText)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                    }
                } else if let limit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDisplayCurrency(limit))
                            .font(AppTheme.Typography.bodySemibold)
                            .foregroundStyle(isOver ? AppTheme.danger : AppTheme.textPrimary)
                        Text(L10n.Main.limit2)
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Text(L10n.Main.noLimit)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if limit != nil && !isEditing {
                AppThinProgressBar(progress: usage, tone: isOver ? .danger : category.tone)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}
