//
//  WeekDetailView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// WeekDetailView.swift
// Features/Learn/Views/

import SwiftUI

struct WeekDetailView: View {
    let weekID: String

    @Environment(LearnViewModel.self)          private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var week: Week? {
        learnVM.publishedWeeks.first { $0.id == weekID }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Week header ────────────────────────────────────────
                    if let week {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WEEK \(week.weekNumber)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "6366F1"))
                            Text(week.title)
                                .font(.system(size: 28, weight: .light, design: .serif))
                                .foregroundStyle(.white)
                            Text(week.description)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }

                    // ── Week progress bar ──────────────────────────────────
                    WeekProgressBar(weekID: weekID)

                    // ── Days list ──────────────────────────────────────────
                    VStack(spacing: 10) {
                        ForEach(learnVM.days(for: weekID)) { day in
                            DayRowCard(
                                day: day,
                                weekID: weekID,
                                progress: learnVM.dayProgress(for: day.id ?? "", in: weekID)
                            )
                            .onTapGesture {
                                handleDayTap(day: day)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await learnVM.loadWeek(weekID: weekID) }
    }

    private func handleDayTap(day: Day) {
        guard let dayID = day.id else { return }
        let progress = learnVM.dayProgress(for: dayID, in: weekID)
        guard progress?.isUnlocked == true else { return }

        if day.isReflection {
            guard learnVM.isReflectionUnlocked(weekID: weekID) else { return }
            coordinator.push(.reflection(weekID, week?.title ?? ""))
        } else if progress?.lessonRead == true && progress?.quizCompleted == false {
            // Lesson done, go straight to quiz
            coordinator.push(.quiz(day.quizID, dayID, weekID))
        } else if progress?.quizCompleted == true {
            // Already complete — show review
            coordinator.push(.quizReview(dayID, weekID))
        } else {
            // Fresh — start with lesson
            coordinator.push(.lessonDetail(day.lessonID, dayID))
        }
    }
}

// MARK: - Week Progress Bar
struct WeekProgressBar: View {
    let weekID: String
    @Environment(LearnViewModel.self) private var learnVM

    private var completedCount: Int {
        let days = learnVM.days(for: weekID).filter { !$0.isReflection }
        return days.filter { day in
            learnVM.dayProgress(for: day.id ?? "", in: weekID)?.isFullyComplete == true
        }.count
    }

    private var totalNonReflection: Int {
        learnVM.days(for: weekID).filter { !$0.isReflection }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount) of \(totalNonReflection) days complete")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "6B7280"))
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(
                            width: totalNonReflection > 0
                                ? geo.size.width * CGFloat(completedCount) / CGFloat(totalNonReflection)
                                : 0,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.5), value: completedCount)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Day Row Card
struct DayRowCard: View {
    let day: Day
    let weekID: String
    let progress: DayProgress?

    private var isLocked:    Bool { progress?.isUnlocked != true }
    private var isComplete:  Bool { progress?.isFullyComplete == true }
    private var lessonDone:  Bool { progress?.lessonRead == true }
    private var quizDone:    Bool { progress?.quizCompleted == true }

    var body: some View {
        HStack(spacing: 14) {
            // ── State icon ─────────────────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBackground)
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // ── Content ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(day.isReflection ? "Reflection Day" : "Day \(day.dayNumber)")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(isLocked ? Color(hex: "374151") : .white)
                    if day.isReflection {
                        Text("📝")
                            .font(.caption)
                    }
                }

                // Sub-status
                if !isLocked && !day.isReflection {
                    HStack(spacing: 10) {
                        StatusDot(done: lessonDone, label: "Lesson")
                        StatusDot(done: quizDone,   label: "Quiz")
                    }
                } else if day.isReflection {
                    Text(isLocked ? "Complete all days first" : "Write your week reflection")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }

                // Score if quiz done
                if let score = progress?.quizScore,
                   let total = progress?.totalQuestions,
                   quizDone {
                    Text("\(score)/\(total) correct")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(progress?.isPassed == true ? Color(hex: "10B981") : Color(hex: "F87171"))
                }
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "374151"))
            }
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1)
        )
        .opacity(isLocked ? 0.4 : 1)
    }

    private var iconName: String {
        if isLocked             { return "lock.fill" }
        if day.isReflection     { return isComplete ? "checkmark" : "pencil" }
        if isComplete           { return "checkmark" }
        if lessonDone           { return "questionmark.circle" }
        return "book"
    }

    private var iconBackground: Color {
        if isComplete           { return Color(hex: "10B981").opacity(0.15) }
        if lessonDone           { return Color(hex: "FACC15").opacity(0.15) }
        if isLocked             { return Color(hex: "1F2937") }
        return Color(hex: "6366F1").opacity(0.15)
    }

    private var iconColor: Color {
        if isComplete           { return Color(hex: "10B981") }
        if lessonDone           { return Color(hex: "FACC15") }
        if isLocked             { return Color(hex: "374151") }
        return Color(hex: "6366F1")
    }

    private var borderColor: Color {
        if isComplete           { return Color(hex: "10B981").opacity(0.3) }
        if lessonDone           { return Color(hex: "FACC15").opacity(0.2) }
        return Color(hex: "1F2937")
    }
}

struct StatusDot: View {
    let done: Bool
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(done ? Color(hex: "10B981") : Color(hex: "374151"))
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(done ? Color(hex: "10B981") : Color(hex: "4B5563"))
        }
    }
}