//
//  SelectableRowCard.swift
//  FinaLit
//

import SwiftUI

struct SelectableRowCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accent: Color
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? accent : OnboardingPalette.muted)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(OnboardingPalette.muted)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accent.opacity(0.1) : OnboardingPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
