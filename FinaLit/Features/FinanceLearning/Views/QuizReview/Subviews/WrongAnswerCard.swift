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
                .foregroundStyle(.white)
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
                .foregroundStyle(Color(hex: "6B7280"))
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "F87171").opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
