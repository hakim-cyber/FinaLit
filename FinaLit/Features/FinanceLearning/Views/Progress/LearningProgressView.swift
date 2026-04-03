//
//  LearningProgressView.swift
//  FinaLit
//

import SwiftUI

struct LearningProgressView: View {
    @Environment(LearnViewModel.self) private var learnVM

    private var summary: LearningSummary { learnVM.learningSummary }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    LevelBadge(level: summary.learningLevel)
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ProgressStatCard(
                            value: "\(summary.totalLessonsRead)",
                            label: "Lessons Read",
                            icon: "book.fill",
                            color: "6366F1"
                        )
                        ProgressStatCard(
                            value: "\(summary.totalQuizzesDone)",
                            label: "Quizzes Done",
                            icon: "checkmark.circle.fill",
                            color: "10B981"
                        )
                        ProgressStatCard(
                            value: "\(summary.currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: "F97316"
                        )
                        ProgressStatCard(
                            value: String(format: "%.0f%%", summary.averageQuizScore),
                            label: "Avg Quiz Score",
                            icon: "chart.bar.fill",
                            color: "FACC15"
                        )
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEK HISTORY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                            .padding(.horizontal, 20)

                        ForEach(learnVM.weekProgressList) { weekProgress in
                            WeekTimelineRow(
                                weekProgress: weekProgress,
                                weekTitle: learnVM.publishedWeeks.first { $0.id == weekProgress.weekID }?.title ?? "Week \(weekProgress.weekNumber)"
                            )
                        }
                    }

                    if !learnVM.reflections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR REFLECTIONS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            ForEach(learnVM.reflections) { reflection in
                                ReflectionHistoryCard(reflection: reflection)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task { await learnVM.loadReflections() }
    }
}
