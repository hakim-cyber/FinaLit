//
//  CategoryRow.swift
//  FinaLit
//

import SwiftUI

struct CategoryRow: View {
    let category: TransactionCategory
    let amount: Double
    let total: Double
    let limit: Double?

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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.tint(for: category.tone))
                        .frame(width: 20)
                    Text(category.rawValue)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(amount))
                        .font(AppTheme.Typography.bodySemibold)
                        .foregroundStyle(isOverBudget ? AppTheme.danger : AppTheme.textPrimary)
                    if let limit {
                        Text("of \(formatCurrency(limit))")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surfaceSecondary)
                        .frame(height: 3)
                    Capsule()
                        .fill(isOverBudget ? AppTheme.danger : AppTheme.tint(for: category.tone))
                        .frame(
                            width: progressBarWidth(totalWidth: geometry.size.width),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 6)
    }

    private func progressBarWidth(totalWidth: CGFloat) -> CGFloat {
        if let limit, limit > 0 {
            return min(totalWidth * CGFloat(amount / limit), totalWidth)
        }
        return totalWidth * CGFloat(percentage / 100)
    }
}
