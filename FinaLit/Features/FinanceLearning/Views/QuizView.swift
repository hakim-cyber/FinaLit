//
//  QuizView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// QuizView.swift
// Features/Learn/Views/

import SwiftUI

struct QuizView: View {
    let quizID:  String
    let dayID:   String
    let weekID:  String

    @Environment(LearnViewModel.self)          private var learnVM
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

                    // ── Progress bar ───────────────────────────────────────
                    QuizProgressBar(
                        current: learnVM.currentQuestionIndex + 1,
                        total: questions.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                    // ── Question ───────────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Question type badge
                            Text(question.type.uppercased())
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "6366F1"))

                            // Question text
                            Text(question.questionText)
                                .font(.system(size: 20, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)

                            // ── Options ────────────────────────────────────
                            VStack(spacing: 10) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    QuizOptionButton(
                                        text:          option,
                                        index:         index,
                                        selectedIndex: selectedIndex,
                                        correctIndex:  question.correctIndex,
                                        isRevealed:    showingExplanation
                                    ) {
                                        guard !showingExplanation else { return }
                                        selectedIndex = index
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingExplanation = true
                                        }
                                        learnVM.answerQuestion(
                                            questionID:    question.id ?? "",
                                            selectedIndex: index
                                        )
                                    }
                                }
                            }

                            // ── Explanation ────────────────────────────────
                            if showingExplanation {
                                ExplanationBox(
                                    isCorrect:   selectedIndex == question.correctIndex,
                                    explanation: question.explanation
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                    }

                    // ── Next button (appears after answering) ──────────────
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
                                .font(.system(size: 16, design: .monospaced))

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
        .navigationBarBackButtonHidden(true) // can't go back mid quiz
        .task { await learnVM.loadQuiz(quizID: quizID) }
        .alert("Error", isPresented: .constant(learnVM.errorMessage != nil)) {
            Button("Try again") {
                Task { await learnVM.loadQuiz(quizID: quizID) }
            }
            Button("OK") { learnVM.clearError() }
        } message: {
            Text(learnVM.errorMessage ?? "")
        }
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
                selectedIndex      = nil
                showingExplanation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                learnVM.advanceToNextQuestion()
            }
        }
    }
}

// MARK: - Quiz Progress Bar
struct QuizProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(current) of \(total)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "6B7280"))
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "6366F1"))
                        .frame(
                            width: geo.size.width * CGFloat(current) / CGFloat(total),
                            height: 3
                        )
                        .animation(.easeInOut(duration: 0.4), value: current)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Quiz Option Button
struct QuizOptionButton: View {
    let text:          String
    let index:         Int
    let selectedIndex: Int?
    let correctIndex:  Int
    let isRevealed:    Bool
    let onTap:         () -> Void

    private var isSelected: Bool { selectedIndex == index }
    private var isCorrect:  Bool { index == correctIndex }

    private var backgroundColor: Color {
        guard isRevealed else {
            return isSelected ? Color(hex: "6366F1").opacity(0.2) : Color(hex: "111118")
        }
        if isCorrect  { return Color(hex: "10B981").opacity(0.15) }
        if isSelected { return Color(hex: "F87171").opacity(0.15) }
        return Color(hex: "111118")
    }

    private var borderColor: Color {
        guard isRevealed else {
            return isSelected ? Color(hex: "6366F1") : Color(hex: "1F2937")
        }
        if isCorrect  { return Color(hex: "10B981") }
        if isSelected { return Color(hex: "F87171") }
        return Color(hex: "1F2937")
    }

    private var textColor: Color {
        guard isRevealed else { return .white }
        if isCorrect  { return Color(hex: "10B981") }
        if isSelected { return Color(hex: "F87171") }
        return Color(hex: "4B5563")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Letter indicator
                ZStack {
                    Circle()
                        .fill(borderColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text(["A","B","C","D"][safe: index] ?? "")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(borderColor)
                }

                Text(text)
                    .font(.system(size: 15, design: .serif))
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

// MARK: - Explanation Box
struct ExplanationBox: View {
    let isCorrect:   Bool
    let explanation: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(isCorrect ? "✓" : "✗")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(isCorrect ? Color(hex: "10B981") : Color(hex: "F87171"))

            VStack(alignment: .leading, spacing: 6) {
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isCorrect ? Color(hex: "10B981") : Color(hex: "F87171"))
                Text(explanation)
                    .font(.system(size: 14, design: .serif))
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

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
