//
//  QuizReviewView.swift
//  FinaLit
//

import SwiftUI

struct QuizReviewView: View {
    let dayID: String
    let weekID: String

    @Environment(LearnViewModel.self) private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var dayProgress: DayProgress? {
        learnVM.dayProgress(for: dayID, in: weekID)
    }

    private var quiz: Quiz? {
        learnVM.currentQuiz
    }

    private var wrongQuestions: [QuizQuestion] {
        guard let quiz else { return [] }
        let wrongIDs = dayProgress?.wrongQuestionIDs ?? []
        return quiz.questions.filter { wrongIDs.contains($0.id) }
    }

    private var score: Int { dayProgress?.quizScore ?? 0 }
    private var total: Int { dayProgress?.totalQuestions ?? 0 }
    private var passed: Bool { dayProgress?.isPassed == true }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    ScoreCard(score: score, total: total, passed: passed)
                        .padding(.top, 8)

                    if wrongQuestions.isEmpty {
                        VStack(spacing: 12) {
                            Text("🏆")
                                .font(.system(size: 48))
                            Text("Perfect score!")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                            Text("You got every question right.")
                                .font(.system(size: 14))
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
                        VStack(alignment: .leading, spacing: 14) {
                            Text("REVIEW YOUR MISTAKES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "F87171"))
                                .padding(.horizontal, 20)

                            ForEach(wrongQuestions) { question in
                                WrongAnswerCard(
                                    question: question,
                                    userIndex: learnVM.currentQuizAnswers[question.id]
                                )
                            }
                        }
                    }

                    Button {
                        coordinator.popToRoot()
                    } label: {
                        Text("Back to Lessons")
                            .font(.system(size: 16))
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
