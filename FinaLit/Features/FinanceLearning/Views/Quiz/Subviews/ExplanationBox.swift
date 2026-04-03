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
                .foregroundStyle(isCorrect ? Color(hex: "10B981") : Color(hex: "F87171"))

            VStack(alignment: .leading, spacing: 6) {
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isCorrect ? Color(hex: "10B981") : Color(hex: "F87171"))
                Text(explanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color(hex: "10B981").opacity(0.08) : Color(hex: "F87171").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCorrect ? Color(hex: "10B981").opacity(0.3) : Color(hex: "F87171").opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}
