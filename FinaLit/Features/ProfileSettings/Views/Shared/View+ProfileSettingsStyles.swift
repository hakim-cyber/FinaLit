//
//  View+ProfileSettingsStyles.swift
//  FinaLit
//

import SwiftUI

private struct ProfileSettingsInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appInputStyle()
    }
}

private struct ProfileSettingsTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appTextAreaStyle()
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
        appFieldLabelStyle()
    }
}
