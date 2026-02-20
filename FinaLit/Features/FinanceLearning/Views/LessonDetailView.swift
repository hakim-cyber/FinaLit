//
//  LessonDetailView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// LessonDetailView.swift
// Features/Learn/Views/

import SwiftUI

struct LessonDetailView: View {
    let lessonID: String
    let dayID: String

    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @State private var scrollOffset: CGFloat = 0
    @State private var hasMarkedRead = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if learnVM.isLoadingLesson {
                LearnLoadingView()
            } else if let lesson = learnVM.currentLesson {
                // ── Scrollable content ─────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        lessonHeader(lesson)

                        // Sections
                        LessonSection(
                            number: "01",
                            title: "What Is It?",
                            content: lesson.conceptDefinition,
                            accent: "6366F1"
                        )
                        LessonSection(
                            number: "02",
                            title: "Why It Matters",
                            content: lesson.whyItMatters,
                            accent: "8B5CF6"
                        )
                        LessonSection(
                            number: "03",
                            title: "Real-Life Example",
                            content: lesson.realLifeExample,
                            accent: "06B6D4"
                        )
                        LessonSection(
                            number: "04",
                            title: "Mini Case",
                            content: lesson.miniCaseScenario,
                            accent: "FACC15",
                            isCase: true
                        )
                        LessonSection(
                            number: "05",
                            title: "Today's Action",
                            content: lesson.dailyActionTask,
                            accent: "10B981",
                            isAction: true
                        )

                        // Bottom padding for button
                        Spacer(minLength: 120)
                    }
                }

                // ── Fixed bottom button ────────────────────────────────────
                VStack(spacing: 0) {
                    // Gradient fade
                    LinearGradient(
                        colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)

                    Button {
                        Task { await handleReadComplete() }
                    } label: {
                        HStack {
                            Text(hasMarkedRead ? "Continue to Quiz →" : "I've read this ✓")
                                .font(.system(size: 16, design: .monospaced))
                            if learnVM.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                        }
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
                    .padding(.bottom, 32)
                    .background(Color(hex: "0A0A0F"))
                    .disabled(learnVM.isSubmitting)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await learnVM.loadLesson(lessonID: lessonID) }
    }

    // MARK: - Header
    private func lessonHeader(_ lesson: Lesson) -> some View {
        let difficulty = DifficultyLevel(rawValue: lesson.difficultyLevel) ?? .beginner

      return  VStack(alignment: .leading, spacing: 12) {
            // Difficulty badge
            Text(lesson.difficultyLevel.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(difficultyColor(difficulty))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(difficultyColor(difficulty).opacity(0.15))
                .clipShape(Capsule())

            Text(lesson.title)
                .font(.system(size: 30, weight: .light, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(4)

            HStack(spacing: 12) {
                Label(lesson.category, systemImage: "tag")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text("·")
                    .foregroundStyle(Color(hex: "374151"))
                Label("Day \(lesson.dayNumber)", systemImage: "calendar")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            Divider()
                .background(Color(hex: "1F2937"))
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .beginner:     return Color(hex: "10B981")
        case .intermediate: return Color(hex: "FACC15")
        case .advanced:     return Color(hex: "F87171")
        }
    }

    // MARK: - Actions
    private func handleReadComplete() async {
        // Find weekID from the days cache
        guard let weekID = findWeekID() else { return }

        if !hasMarkedRead {
            let didMarkRead = await learnVM.markLessonRead(weekID: weekID, dayID: dayID)
            guard didMarkRead else { return }
            hasMarkedRead = true
        }

        // Navigate to quiz
        let days = learnVM.daysCache.values.flatMap { $0 }
        if let day = days.first(where: { $0.id == dayID }) {
            coordinator.push(.quiz(day.quizID, dayID, weekID))
        }
    }

    private func findWeekID() -> String? {
        for (weekID, days) in learnVM.daysCache {
            if days.contains(where: { $0.id == dayID }) {
                return weekID
            }
        }
        return nil
    }
}

// MARK: - Lesson Section
struct LessonSection: View {
    let number: String
    let title: String
    let content: String
    let accent: String
    var isCase: Bool   = false
    var isAction: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack(spacing: 10) {
                Text(number)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: accent))
                Rectangle()
                    .fill(Color(hex: accent).opacity(0.4))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            // Content
            if isAction {
                // Action box
                HStack(alignment: .top, spacing: 12) {
                    Text("→")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Color(hex: accent))
                    Text(content)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color(hex: "D1FAE5"))
                        .lineSpacing(5)
                }
                .padding(16)
                .background(Color(hex: "10B981").opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1)
                )
            } else if isCase {
                // Case scenario box
                Text(content)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Color(hex: "FEF3C7"))
                    .lineSpacing(5)
                    .italic()
                    .padding(16)
                    .background(Color(hex: "FACC15").opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "FACC15").opacity(0.2), lineWidth: 1)
                    )
            } else {
                Text(content)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Color(hex: "D1D5DB"))
                    .lineSpacing(6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)

        Divider()
            .background(Color(hex: "111118"))
            .padding(.horizontal, 20)
    }
}
