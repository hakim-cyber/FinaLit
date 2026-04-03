//
//  ProfileSettingsTogglePill.swift
//  FinaLit
//

import SwiftUI

struct ProfileSettingsTogglePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : ProfileSettingsPalette.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? tint.opacity(0.2) : ProfileSettingsPalette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? tint : ProfileSettingsPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
