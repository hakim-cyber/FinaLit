//
//  ProfileSettingsSelectableRow.swift
//  FinaLit
//

import SwiftUI

struct ProfileSettingsSelectableRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(accent.opacity(isSelected ? 1 : 0.35))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(ProfileSettingsPalette.muted)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .appSurface(isSelected ? .tinted(.accent) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
