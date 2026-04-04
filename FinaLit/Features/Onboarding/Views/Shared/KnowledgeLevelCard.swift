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
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(OnboardingPalette.accent)
                    }
                }

                Text(description)
                    .font(AppTheme.Typography.detail)
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
            .appSurface(isSelected ? .tinted(.accent) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
