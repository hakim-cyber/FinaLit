//
//  QuickActionCard.swift
//  FinaLit
//

import SwiftUI

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tone: AppTone
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.softFill(for: tone))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.tint(for: tone))
                }

                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .appSurface(.primary, padding: AppTheme.Spacing.card, cornerRadius: AppTheme.CornerRadius.large)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}
