//
//  WrongAnswerCard.swift
//  FinaLit
//

import SwiftUI

struct WrongAnswerCard: View {
    let question: QuizQuestion
    let userIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.questionText)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(4)

            if let userIndex, userIndex < question.options.count {
                AnswerRow(
                    label: "Your answer",
                    text: question.options[userIndex],
                    correct: false
                )
            }

            AnswerRow(
                label: "Correct answer",
                text: question.options[safe: question.correctIndex] ?? "",
                correct: true
            )

            Text(question.explanation)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .padding(16)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.danger.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
