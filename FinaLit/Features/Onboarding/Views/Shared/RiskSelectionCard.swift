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
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(OnboardingPalette.muted)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tint.opacity(0.14) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tint : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
