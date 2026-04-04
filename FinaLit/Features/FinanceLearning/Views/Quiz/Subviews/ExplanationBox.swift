//
//  ExplanationBox.swift
//  FinaLit
//

import SwiftUI

struct ExplanationBox: View {
    let isCorrect: Bool
    let explanation: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(isCorrect ? "✓" : "✗")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isCorrect ? AppTheme.success : AppTheme.danger)

            VStack(alignment: .leading, spacing: 6) {
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isCorrect ? AppTheme.success : AppTheme.danger)
                Text(explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? AppTheme.success.opacity(0.08) : AppTheme.danger.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCorrect ? AppTheme.success.opacity(0.3) : AppTheme.danger.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}
