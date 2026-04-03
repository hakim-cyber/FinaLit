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
            return isSelected ? Color(hex: "6366F1").opacity(0.2) : Color(hex: "111118")
        }
        if isCorrect { return Color(hex: "10B981").opacity(0.15) }
        if isSelected { return Color(hex: "F87171").opacity(0.15) }
        return Color(hex: "111118")
    }

    private var borderColor: Color {
        guard isRevealed else {
            return isSelected ? Color(hex: "6366F1") : Color(hex: "1F2937")
        }
        if isCorrect { return Color(hex: "10B981") }
        if isSelected { return Color(hex: "F87171") }
        return Color(hex: "1F2937")
    }

    private var textColor: Color {
        guard isRevealed else { return .white }
        if isCorrect { return Color(hex: "10B981") }
        if isSelected { return Color(hex: "F87171") }
        return Color(hex: "4B5563")
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
                        .foregroundStyle(isCorrect ? Color(hex: "10B981") : Color(hex: "F87171"))
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
