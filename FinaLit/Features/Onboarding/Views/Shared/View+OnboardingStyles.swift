//
//  View+OnboardingStyles.swift
//  FinaLit
//

import SwiftUI

private struct OnboardingInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OnboardingPalette.border, lineWidth: 1)
            )
    }
}

private struct OnboardingTextAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .padding(14)
            .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(OnboardingPalette.border, lineWidth: 1)
            )
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
        font(.system(size: 11, weight: .semibold))
            .foregroundStyle(OnboardingPalette.muted)
    }
}
