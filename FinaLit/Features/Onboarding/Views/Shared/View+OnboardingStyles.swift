//
//  View+OnboardingStyles.swift
//  FinaLit
//

import SwiftUI

private struct OnboardingInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appInputStyle()
    }
}

private struct OnboardingTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appTextAreaStyle()
    }
}

extension View {
    func onboardingInputStyle() -> some View {
        modifier(OnboardingInputFieldModifier())
    }

    func onboardingTextAreaStyle() -> some View {
        modifier(OnboardingTextAreaModifier())
    }

    func onboardingFieldLabelStyle() -> some View {
        appFieldLabelStyle()
    }
}
