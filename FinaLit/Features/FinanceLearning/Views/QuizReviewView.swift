//
//  QuizReviewView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// QuizReviewView.swift
// Features/Learn/Views/

import SwiftUI

struct QuizReviewView: View {
    let dayID:  String
    let weekID: String

    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var dayProgress: DayProgress? {
        learnVM.dayProgress(for: dayID, in: weekID)
    }

    private var quiz: Quiz? { learnVM.currentQuiz }

    private var wrongQuestions: [QuizQuestion] {
        guard let quiz else { return [] }
        let wrongIDs = dayProgress?.wrongQuestionIDs ?? []
        return quiz.questions.filter { wrongIDs.contains($0.id) }
    }

    private var score: Int    { dayProgress?.quizScore ?? 0 }
    private var total: Int    { dayProgress?.totalQuestions ?? 0 }
    private var passed: Bool  { dayProgress?.isPassed == true }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // ── Score card ─────────────────────────────────────────
                    ScoreCard(score: score, total: total, passed: passed)
                        .padding(.top, 8)

                    if wrongQuestions.isEmpty {
                        // Perfect score
                        VStack(spacing: 12) {
                            Text("🏆")
                                .font(.system(size: 48))
                            Text("Perfect score!")
                                .font(.system(size: 22, design: .serif))
                                .foregroundStyle(.white)
                            Text("You got every question right.")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // Wrong answers review
                        VStack(alignment: .leading, spacing: 14) {
                            Text("REVIEW YOUR MISTAKES")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "F87171"))
                                .padding(.horizontal, 20)

                            ForEach(wrongQuestions) { question in
                                WrongAnswerCard(
                                    question:      question,
                                    userIndex:     learnVM.currentQuizAnswers[question.id]
                                )
                            }
                        }
                    }

                    // ── Done button ────────────────────────────────────────
                    Button {
                        coordinator.popToRoot()
                    } label: {
                        Text("Back to Lessons")
                            .font(.system(size: 16, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Quiz Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Score Card
struct ScoreCard: View {
    let score:  Int
    let total:  Int
    let passed: Bool

    private var percentage: Int {
        total > 0 ? Int((Double(score) / Double(total)) * 100) : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            // Big score
            VStack(spacing: 6) {
                Text("\(score)/\(total)")
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)
                Text("\(percentage)% correct")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
            }

            // Pass/fail badge
            HStack(spacing: 6) {
                Circle()
                    .fill(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
                    .frame(width: 8, height: 8)
                Text(passed ? "Day Complete — Next day unlocked" : "Keep studying — You'll get it!")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(passed ? Color(hex: "10B981") : Color(hex: "F87171"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                (passed ? Color(hex: "10B981") : Color(hex: "F87171")).opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    passed ? Color(hex: "10B981").opacity(0.3) : Color(hex: "F87171").opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Wrong Answer Card
struct WrongAnswerCard: View {
    let question:  QuizQuestion
    let userIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Question
            Text(question.questionText)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(4)

            // Your answer
            if let userIndex, userIndex < question.options.count {
                AnswerRow(
                    label:   "Your answer",
                    text:    question.options[userIndex],
                    correct: false
                )
            }

            // Correct answer
            AnswerRow(
                label:   "Correct answer",
                text:    question.options[safe: question.correctIndex] ?? "",
                correct: true
            )

            // Explanation
            Text(question.explanation)
                .font(.system(size: 13, design: .monospaced))
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

struct AnswerRow: View {
    let label:   String
    let text:    String
    let correct: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? Color(hex: "10B981") : Color(hex: "F87171"))
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(text)
                    .font(.system(size: 14, design: .serif))
                    .foregroundStyle(correct ? Color(hex: "10B981") : Color(hex: "F87171"))
            }
        }
    }
}
