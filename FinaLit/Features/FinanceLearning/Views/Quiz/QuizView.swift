//
//  QuizView.swift
//  FinaLit
//

import SwiftUI

struct QuizView: View {
    let quizID: String
    let dayID: String
    let weekID: String

    @Environment(LearnViewModel.self) private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @State private var showingExplanation = false
    @State private var selectedIndex: Int?

    private var questions: [QuizQuestion] {
        learnVM.currentQuiz?.questions ?? []
    }

    private var currentQuestion: QuizQuestion? {
        guard learnVM.currentQuestionIndex < questions.count else { return nil }
        return questions[learnVM.currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        learnVM.currentQuestionIndex == questions.count - 1
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if learnVM.isLoadingQuiz {
                LearnLoadingView()
            } else if let question = currentQuestion {
                VStack(spacing: 0) {
                    QuizProgressBar(
                        current: learnVM.currentQuestionIndex + 1,
                        total: questions.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(question.type.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "6366F1"))

                            Text(question.questionText)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 10) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    QuizOptionButton(
                                        text: option,
                                        index: index,
                                        selectedIndex: selectedIndex,
                                        correctIndex: question.correctIndex,
                                        isRevealed: showingExplanation
                                    ) {
                                        guard !showingExplanation else { return }
                                        selectedIndex = index
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingExplanation = true
                                        }
                                        learnVM.answerQuestion(
                                            questionID: question.id,
                                            selectedIndex: index
                                        )
                                    }
                                }
                            }

                            if showingExplanation {
                                ExplanationBox(
                                    isCorrect: selectedIndex == question.correctIndex,
                                    explanation: question.explanation
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                    }

                    if showingExplanation {
                        Button {
                            handleNext()
                        } label: {
                            HStack(spacing: 10) {
                                Text(
                                    learnVM.isSubmitting && isLastQuestion
                                        ? "Loading Results..."
                                        : (isLastQuestion ? "See Results →" : "Next Question →")
                                )
                                .font(.system(size: 16))

                                if learnVM.isSubmitting && isLastQuestion {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.85)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                learnVM.isSubmitting
                                    ? LinearGradient(
                                        colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(learnVM.isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }

            if learnVM.isSubmitting {
                LearnLoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await learnVM.loadQuiz(quizID: quizID) }
        .alert("Error", isPresented: isShowingErrorAlert) {
            Button("Try again") {
                Task { await learnVM.loadQuiz(quizID: quizID) }
            }
            Button("OK") { learnVM.clearError() }
        } message: {
            Text(learnVM.errorMessage ?? "")
        }
    }

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { learnVM.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    learnVM.clearError()
                }
            }
        )
    }

    private func handleNext() {
        if isLastQuestion {
            Task {
                let didSave = await learnVM.submitQuiz(weekID: weekID, dayID: dayID)
                if didSave {
                    coordinator.push(.quizReview(dayID, weekID))
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = nil
                showingExplanation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                learnVM.advanceToNextQuestion()
            }
        }
    }
}
