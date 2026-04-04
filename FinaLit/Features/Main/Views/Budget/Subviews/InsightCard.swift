//
//  InsightCard.swift
//  FinaLit
//

import SwiftUI

struct InsightCard: View {
    let insight: SmartInsight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: insight.icon)
                .font(AppTheme.Typography.rowIcon)
                .foregroundStyle(AppTheme.tint(for: insight.tone))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 5) {
                Text(insight.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(insight.message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
