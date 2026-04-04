//
//  TotalBudgetCard.swift
//  FinaLit
//

import SwiftUI

struct TotalBudgetCard: View {
    let spent: Double
    let totalLimit: Double

    private var usage: Double {
        guard totalLimit > 0 else { return 0 }
        return min(spent / totalLimit, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Total budget")
                    .font(AppTheme.Typography.formLabel)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                if totalLimit > 0 {
                    Text("\(formatCurrency(spent)) / \(formatCurrency(totalLimit))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(spent > totalLimit ? AppTheme.danger : AppTheme.textPrimary)
                }
            }
            if totalLimit > 0 {
                AppThinProgressBar(progress: usage, tone: spent > totalLimit ? .danger : .accent)
            } else {
                Text("Set limits above to track your total budget.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
