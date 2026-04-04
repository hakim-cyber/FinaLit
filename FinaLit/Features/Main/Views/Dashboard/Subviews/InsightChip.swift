//
//  InsightChip.swift
//  FinaLit
//

import SwiftUI

struct InsightChip: View {
    let insight: SmartInsight

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.tint(for: insight.tone))
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(insight.message)
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .appSurface(.tinted(insight.tone), padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
        .frame(width: 220, alignment: .leading)
    }
}
