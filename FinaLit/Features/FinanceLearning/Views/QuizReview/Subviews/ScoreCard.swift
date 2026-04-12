//
//  ScoreCard.swift
//  FinaLit
//

import SwiftUI

struct ScoreCard: View {
    let score: Int
    let total: Int
    let passed: Bool
    @Environment(AppPreferencesStore.self) private var preferences

    private var percentage: Int {
        total > 0 ? Int((Double(score) / Double(total)) * 100) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("\(score)/\(total)")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(percentage)% \(String(localized: "learning.correctSuffix"))")
                    .font(.system(size: 14))
                    .foregroundStyle(passed ? AppTheme.success : AppTheme.danger)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(passed ? AppTheme.success : AppTheme.danger)
                    .frame(width: 8, height: 8)
                Text(passed ? String(localized: "learning.dayCompleteNextDayUnlocked") : String(localized: "learning.keepStudying"))
                    .font(.system(size: 12))
                    .foregroundStyle(passed ? AppTheme.success : AppTheme.danger)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background((passed ? AppTheme.success : AppTheme.danger).opacity(0.1))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    passed ? AppTheme.success.opacity(0.3) : AppTheme.danger.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, 20)
    }
}
