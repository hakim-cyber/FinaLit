//
//  StatMiniCard.swift
//  FinaLit
//

import SwiftUI

struct StatMiniCard: View {
    let label: String
    let value: String
    let icon: String
    let tone: AppTone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(label)
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.tint(for: tone))
                    .font(AppTheme.Typography.rowIcon)
            }

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minHeight: AppTheme.Metrics.statCardMinHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.secondary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
    }
}
