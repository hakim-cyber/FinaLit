//
//  InsightCard.swift
//  FinaLit
//

import SwiftUI

struct InsightCard: View {
    let insight: SmartInsight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.softFill(for: insight.tone))
                    .frame(width: 38, height: 38)
                Image(systemName: insight.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.tint(for: insight.tone))
            }
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
        }
        .appSurface(.tinted(insight.tone), padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
