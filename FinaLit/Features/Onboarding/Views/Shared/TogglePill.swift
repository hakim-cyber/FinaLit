//
//  TogglePill.swift
//  FinaLit
//

import SwiftUI

struct TogglePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : OnboardingPalette.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? tint.opacity(0.2) : OnboardingPalette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(isSelected ? tint : OnboardingPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
