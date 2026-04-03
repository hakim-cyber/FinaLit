//
//  QuizQuestionDraftView.swift
//  FinaLit
//

import SwiftUI

struct QuizQuestionDraftView: View {
    let index: Int
    @Environment(AdminViewModel.self) private var adminVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUESTION \(index + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "6366F1"))
                Spacer()
                if adminVM.questions.count > 1 {
                    Button {
                        adminVM.removeQuestion(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color(hex: "F87171"))
                            .font(.system(size: 13))
                    }
                }
            }

            AdminTextArea(
                label: "QUESTION TEXT",
                placeholder: "What is opportunity cost?",
                text: Binding(
                    get: { adminVM.questions[safe: index]?.questionText ?? "" },
                    set: { adminVM.questions[index].questionText = $0 }
                )
            )

            Picker("Type", selection: Binding(
                get: { adminVM.questions[safe: index]?.type ?? .multipleChoice },
                set: { adminVM.questions[index].type = $0 }
            )) {
                Text("Multiple Choice").tag(QuizQuestionType.multipleChoice)
                Text("Scenario").tag(QuizQuestionType.scenario)
            }
            .pickerStyle(.segmented)
            .tint(Color(hex: "6366F1"))

            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { optionIndex in
                    HStack(spacing: 10) {
                        Button {
                            adminVM.questions[index].correctIndex = optionIndex
                        } label: {
                            Image(systemName: adminVM.questions[safe: index]?.correctIndex == optionIndex ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(adminVM.questions[safe: index]?.correctIndex == optionIndex ? Color(hex: "10B981") : Color(hex: "374151"))
                        }

                        TextField(
                            "Option \(["A", "B", "C", "D"][optionIndex])",
                            text: Binding(
                                get: { adminVM.questions[safe: index]?.options[safe: optionIndex] ?? "" },
                                set: { adminVM.questions[index].options[optionIndex] = $0 }
                            )
                        )
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
            .background(Color(hex: "0D0D14"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("● = correct answer")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "4B5563"))

            AdminTextArea(
                label: "EXPLANATION (shown after answering)",
                placeholder: "Opportunity cost is...",
                text: Binding(
                    get: { adminVM.questions[safe: index]?.explanation ?? "" },
                    set: { adminVM.questions[index].explanation = $0 }
                )
            )
        }
        .padding(14)
        .background(Color(hex: "0D0D14"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
