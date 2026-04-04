//
//  RiskSelectionCard.swift
//  FinaLit
//

import SwiftUI

struct RiskSelectionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(tint.opacity(isSelected ? 1 : 0.35))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(OnboardingPalette.muted)
                }

                Spacer()
            }
            .appSurface(isSelected ? .tinted(.accent) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
