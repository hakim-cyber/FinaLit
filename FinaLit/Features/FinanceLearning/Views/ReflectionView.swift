//
//  ReflectionView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// ReflectionView.swift
// Features/Learn/Views/

import SwiftUI

struct ReflectionView: View {
    let weekID:    String
    let weekTitle: String

    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @State private var content: String = ""
    @FocusState private var isFocused: Bool

    private let minLength = 100
    private var canSubmit: Bool { content.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength }
    private var charCount: Int  { content.trimmingCharacters(in: .whitespacesAndNewlines).count }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Header ─────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📝")
                            .font(.system(size: 36))
                        Text("Week Reflection")
                            .font(.system(size: 30, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        Text(weekTitle)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color(hex: "6366F1"))
                    }

                    // ── Prompts ────────────────────────────────────────────
                    VStack(spacing: 10) {
                        ReflectionPrompt(number: "01", text: "What concept stuck with you most this week?")
                        ReflectionPrompt(number: "02", text: "Did you change any financial decision based on what you learned?")
                        ReflectionPrompt(number: "03", text: "What will you do differently going forward?")
                    }

                    // ── Text editor ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR REFLECTION")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write your thoughts here... (min \(minLength) characters)")
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundStyle(Color(hex: "374151"))
                                    .padding(.top, 14)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .font(.system(size: 15, design: .serif))
                                .foregroundStyle(Color(hex: "D1D5DB"))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(12)
                                .frame(minHeight: 180)
                                .focused($isFocused)
                        }
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isFocused ? Color(hex: "6366F1").opacity(0.5) : Color(hex: "1F2937"),
                                    lineWidth: 1.5
                                )
                        )

                        // Character counter
                        HStack {
                            if !canSubmit && charCount > 0 {
                                Text("\(minLength - charCount) more characters needed")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: "F87171"))
                            } else if canSubmit {
                                Text("✓ Ready to submit")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(hex: "10B981"))
                            }
                            Spacer()
                            Text("\(charCount)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(canSubmit ? Color(hex: "10B981") : Color(hex: "4B5563"))
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // ── Submit button ──────────────────────────────────────────────
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(hex: "0A0A0F").opacity(0), Color(hex: "0A0A0F")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)

                Button {
                    isFocused = false
                    Task {
                        let success = await learnVM.submitReflection(
                            weekID:    weekID,
                            weekTitle: weekTitle,
                            content:   content
                        )
                        if success {
                            coordinator.popToRoot()
                        }
                    }
                } label: {
                    HStack {
                        Text("Submit Reflection")
                            .font(.system(size: 16, design: .monospaced))
                        if learnVM.isSubmitting {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        canSubmit
                            ? LinearGradient(
                                colors: [Color(hex: "10B981"), Color(hex: "059669")],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                            : LinearGradient(
                                colors: [Color(hex: "1F2937"), Color(hex: "1F2937")],
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                    )
                    .foregroundStyle(canSubmit ? .white : Color(hex: "374151"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(Color(hex: "0A0A0F"))
                .disabled(!canSubmit || learnVM.isSubmitting)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: isShowingErrorAlert) {
            Button("Try again") {
                Task {
                    let success = await learnVM.submitReflection(
                        weekID: weekID,
                        weekTitle: weekTitle,
                        content: content
                    )
                    if success {
                        coordinator.popToRoot()
                    }
                }
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
}

struct ReflectionPrompt: View {
    let number: String
    let text:   String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "6366F1"))
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Color(hex: "9CA3AF"))
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ─────────────────────────────────────────────────────────────────────────────

// LearningProgressView.swift
// Features/Learn/Views/

struct LearningProgressView: View {
    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var summary: LearningSummary { learnVM.learningSummary }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Level badge ────────────────────────────────────────
                    LevelBadge(level: summary.learningLevel)
                        .padding(.top, 8)

                    // ── Stats grid ─────────────────────────────────────────
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

                    // ── Week timeline ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEK HISTORY")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                            .padding(.horizontal, 20)

                        ForEach(learnVM.weekProgressList) { wp in
                            WeekTimelineRow(
                                weekProgress: wp,
                                weekTitle: learnVM.publishedWeeks.first { $0.id == wp.weekID }?.title ?? "Week \(wp.weekNumber)"
                            )
                        }
                    }

                    // ── Reflections ────────────────────────────────────────
                    if !learnVM.reflections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR REFLECTIONS")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
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

// MARK: - Level Badge
struct LevelBadge: View {
    let level: LearningLevel

    private var levelColor: String {
        switch level {
        case .beginner:        return "6B7280"
        case .learner:         return "6366F1"
        case .skilled:         return "10B981"
        case .financialThinker: return "FACC15"
        }
    }

    private var levelEmoji: String {
        switch level {
        case .beginner:        return "🌱"
        case .learner:         return "📈"
        case .skilled:         return "💡"
        case .financialThinker: return "🏆"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(levelEmoji)
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR LEVEL")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                Text(level.rawValue)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: levelColor))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: levelColor).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: levelColor).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Progress Stat Card
struct ProgressStatCard: View {
    let value: String
    let label: String
    let icon:  String
    let color: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: color))
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}

// MARK: - Week Timeline Row
struct WeekTimelineRow: View {
    let weekProgress: WeekProgress
    let weekTitle:    String

    var body: some View {
        HStack(spacing: 14) {
            // Dot
            ZStack {
                Circle()
                    .fill(weekProgress.isCompleted ? Color(hex: "10B981") : Color(hex: "1F2937"))
                    .frame(width: 10, height: 10)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(weekTitle)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(weekProgress.isCompleted ? .white : Color(hex: "4B5563"))
                if let date = weekProgress.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6B7280"))
                } else if weekProgress.isUnlocked {
                    Text("In progress")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                } else {
                    Text("Locked")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "374151"))
                }
            }

            Spacer()

            if weekProgress.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "10B981"))
                    .font(.system(size: 16))
            } else if weekProgress.isUnlocked {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(Color(hex: "6366F1"))
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Reflection History Card
struct ReflectionHistoryCard: View {
    let reflection: Reflection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(reflection.weekTitle)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                Spacer()
                Text(reflection.submittedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Text(reflection.content)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color(hex: "6B7280"))
                .lineLimit(3)
                .lineSpacing(3)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
