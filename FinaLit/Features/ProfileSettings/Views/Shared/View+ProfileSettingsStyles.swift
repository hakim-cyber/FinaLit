//
//  View+ProfileSettingsStyles.swift
//  FinaLit
//

import SwiftUI

private struct ProfileSettingsInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(ProfileSettingsPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ProfileSettingsPalette.border, lineWidth: 1)
            )
    }
}

private struct ProfileSettingsTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .padding(14)
            .background(ProfileSettingsPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ProfileSettingsPalette.border, lineWidth: 1)
            )
    }
}

extension View {
    func settingsInputStyle() -> some View {
        modifier(ProfileSettingsInputFieldModifier())
    }

    func settingsTextAreaStyle() -> some View {
        modifier(ProfileSettingsTextAreaModifier())
    }

    func settingsFieldLabelStyle() -> some View {
        font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ProfileSettingsPalette.muted)
    }
}
