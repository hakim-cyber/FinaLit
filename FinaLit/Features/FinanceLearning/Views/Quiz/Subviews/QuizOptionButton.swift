//
//  QuizOptionButton.swift
//  FinaLit
//

import SwiftUI

struct QuizOptionButton: View {
    let text: String
    let index: Int
    let selectedIndex: Int?
    let correctIndex: Int
    let isRevealed: Bool
    let onTap: () -> Void

    private var isSelected: Bool { selectedIndex == index }
    private var isCorrect: Bool { index == correctIndex }

    private var backgroundColor: Color {
        guard isRevealed else {
            return isSelected ? AppTheme.accent.opacity(0.2) : AppTheme.surfacePrimary
        }
        if isCorrect { return AppTheme.success.opacity(0.15) }
        if isSelected { return AppTheme.danger.opacity(0.15) }
        return AppTheme.surfacePrimary
    }

    private var borderColor: Color {
        guard isRevealed else {
            return isSelected ? AppTheme.accent : AppTheme.separator
        }
        if isCorrect { return AppTheme.success }
        if isSelected { return AppTheme.danger }
        return AppTheme.separator
    }

    private var textColor: Color {
        guard isRevealed else { return AppTheme.textPrimary }
        if isCorrect { return AppTheme.success }
        if isSelected { return AppTheme.danger }
        return AppTheme.textSecondary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(borderColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text(["A", "B", "C", "D"][safe: index] ?? "")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(borderColor)
                }

                Text(text)
                    .font(.system(size: 15))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isRevealed {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .foregroundStyle(isCorrect ? AppTheme.success : AppTheme.danger)
                        .opacity((isCorrect || isSelected) ? 1 : 0)
                }
            }
            .padding(14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: isRevealed)
        }
        .disabled(isRevealed)
    }
}
