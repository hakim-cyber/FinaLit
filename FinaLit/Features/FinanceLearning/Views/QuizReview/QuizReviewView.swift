//
//  QuizReviewView.swift
//  FinaLit
//

import SwiftUI

struct QuizReviewView: View {
    let dayID: String
    let weekID: String

    @Environment(LearnViewModel.self) private var learnVM
    @Environment(AppPreferencesStore.self) private var preferences
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var day: Day? {
        learnVM.days(for: weekID).first { $0.id == dayID }
    }

    private var dayProgress: DayProgress? {
        learnVM.dayProgress(for: dayID, in: weekID)
    }

    private var quiz: Quiz? {
        guard let quizID = day?.quizID else { return nil }
        guard learnVM.currentQuiz?.id == quizID else { return nil }
        return learnVM.currentQuiz?.resolved(for: preferences.effectiveLearningLanguage)
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
            AppTheme.background.ignoresSafeArea()

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
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("You got every question right.")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(AppTheme.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.success.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("REVIEW YOUR MISTAKES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.danger)
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
                                    colors: [AppTheme.accent, AppTheme.accent],
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LearningLanguageMenu()
            }
        }
        .task(id: day?.quizID) {
            guard let quizID = day?.quizID else { return }
            guard learnVM.currentQuiz?.id != quizID else { return }
            await learnVM.loadQuiz(quizID: quizID)
        }
    }
}
