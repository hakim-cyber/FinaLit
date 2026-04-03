//
//  ChipButton.swift
//  FinaLit
//

import SwiftUI

struct ChipButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.white : OnboardingPalette.muted)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? OnboardingPalette.accent.opacity(0.18) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? OnboardingPalette.accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
