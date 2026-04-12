//
//  AddQuizView.swift
//  FinaLit
//

import SwiftUI

struct AddQuizView: View {
    let dayID: String
    @Environment(AdminViewModel.self) private var adminVM
    @State private var savedQuizID: String?

    var body: some View {
        var adminVM = Bindable(adminVM)
        AdminFormView(title: "Add Quiz", icon: "questionmark.circle.fill") {
            AdminField(label: "DOCUMENT ID (OPTIONAL)", placeholder: "Reuse an existing quiz ID to update the same document", text: adminVM.quizDocumentID)
            Button(L10n.Admin.loadExistingQuiz) {
                Task { _ = await self.adminVM.loadQuizForEditing() }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(hex: "6366F1"))
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                AdminField(label: "WEEK #", placeholder: "1", text: adminVM.quizWeekNumber)
                    .keyboardType(.numberPad)
                AdminField(label: "DAY #", placeholder: "1", text: adminVM.quizDayNumber)
                    .keyboardType(.numberPad)
            }

            ForEach(Array(self.adminVM.questions.enumerated()), id: \.element.id) { index, _ in
                QuizQuestionDraftView(index: index)
            }

            Button {
                self.adminVM.addQuestion()
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text(L10n.Admin.addQuestion)
                }
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6366F1"))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "6366F1").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            AdminSaveButton(label: "Save Quiz", isLoading: self.adminVM.isLoading) {
                Task {
                    let (saved, id) = await self.adminVM.saveQuiz()
                    if saved {
                        savedQuizID = id
                    }
                }
            }

            if let success = self.adminVM.successMessage {
                Text(success)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(14)
                    .background(Color(hex: "10B981").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let savedQuizID {
                AdminCreatedIDCard(
                    title: "Quiz ID",
                    value: savedQuizID,
                    hint: "Paste this into Add Day → QUIZ ID"
                )
            }
        }
        .adminFeedback(success: nil, error: self.adminVM.errorMessage) {
            self.adminVM.clearMessages()
        }
    }
}
