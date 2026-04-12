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
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    LevelBadge(level: summary.learningLevel)
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ProgressStatCard(
                            value: "\(summary.totalLessonsRead)",
                            label: "Lessons Read",
                            icon: "book.fill",
                            tone: .accent
                        )
                        ProgressStatCard(
                            value: "\(summary.totalQuizzesDone)",
                            label: "Quizzes Done",
                            icon: "checkmark.circle.fill",
                            tone: .success
                        )
                        ProgressStatCard(
                            value: "\(summary.currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            tone: .orange
                        )
                        ProgressStatCard(
                            value: String(format: "%.0f%%", summary.averageQuizScore),
                            label: "Avg Quiz Score",
                            icon: "chart.bar.fill",
                            tone: .warning
                        )
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader(title: "Week history")
                            .padding(.horizontal,20)

                        ForEach(learnVM.weekProgressList) { weekProgress in
                            WeekTimelineRow(
                                weekProgress: weekProgress,
                                weekTitle: learnVM.publishedWeeks.first { $0.id == weekProgress.weekID }?.title ?? "Week \(weekProgress.weekNumber)"
                            )
                        }
                    }

                    if !learnVM.reflections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            AppSectionHeader(title: "Your reflections")

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
        .navigationTitle(L10n.Common.yourProgress)
        .navigationBarTitleDisplayMode(.inline)
        .task { await learnVM.loadReflections() }
    }
}
