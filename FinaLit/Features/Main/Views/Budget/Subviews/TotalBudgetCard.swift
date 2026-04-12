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
                Text(L10n.Main.totalBudget)
                    .font(AppTheme.Typography.formLabel)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                if totalLimit > 0 {
                    Text("\(formatDisplayCurrency(spent)) / \(formatDisplayCurrency(totalLimit))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(spent > totalLimit ? AppTheme.danger : AppTheme.textPrimary)
                }
            }
            if totalLimit > 0 {
                AppThinProgressBar(progress: usage, tone: spent > totalLimit ? .danger : .accent)
            } else {
                Text(L10n.Main.setLimitsAboveToTrackYourTotalBudget)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
