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
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.softFill(for: category.tone))
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.tint(for: category.tone))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(AppTheme.Typography.bodySemibold)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Spent: \(formatCurrency(spent))")
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                if isEditing {
                    HStack(spacing: 4) {
                        Text(AppRegion.currencySymbol)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Limit", text: $editingText)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .multilineTextAlignment(.trailing)
                    }
                } else if let limit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(limit))
                            .font(AppTheme.Typography.bodySemibold)
                            .foregroundStyle(isOver ? AppTheme.danger : AppTheme.textPrimary)
                        Text("limit")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Text("No limit")
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if limit != nil && !isEditing {
                AppThinProgressBar(progress: usage, tone: isOver ? .danger : category.tone)
            }
        }
        .appSurface(isOver ? .tinted(.danger) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.large)
    }
}
