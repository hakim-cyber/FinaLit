//
//  KnowledgeLevelCard.swift
//  FinaLit
//

import SwiftUI

struct KnowledgeLevelCard: View {
    let title: String
    let description: String
    let level: Double
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OnboardingPalette.accent)
                    }
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(OnboardingPalette.muted)

                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(OnboardingPalette.border)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(OnboardingPalette.accent)
                                .frame(width: geometry.size.width * level)
                        }
                }
                .frame(height: 8)
            }
            .padding(14)
            .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? OnboardingPalette.accent : OnboardingPalette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
