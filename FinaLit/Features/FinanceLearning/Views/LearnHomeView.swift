//
//  LearnHomeView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// LearnHomeView.swift
// Features/Learn/Views/

import SwiftUI

struct LearnHomeView: View {
    @Environment(LearnViewModel.self)              private var learnVM
    @Environment(Coordinator<LearnPages>.self)     private var coordinator
    @Environment(UserSession.self)                 private var session

    var body: some View {
        ZStack {
            // ── Background ─────────────────────────────────────────────────
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Header ─────────────────────────────────────────────
                    headerSection

                    // ── Daily Tip ──────────────────────────────────────────
                    if let tip = learnVM.todaysTip {
                        DailyTipCard(tip: tip)
                    }

                    // ── Continue Banner ────────────────────────────────────
                    if let next = learnVM.nextUnlockedDay {
                        ContinueBanner(weekID: next.weekID, dayID: next.dayID, dayNumber: next.dayNumber)
                    }

                    // ── Stats Strip ────────────────────────────────────────
                    StatsStrip(summary: learnVM.learningSummary)
                        .onTapGesture { coordinator.push(.progress) }

                    // ── Weeks ──────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR CURRICULUM")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "4B5563"))
                            .padding(.horizontal, 20)

                        if let errorMessage = learnVM.errorMessage,
                           learnVM.publishedWeeks.isEmpty,
                           !learnVM.isLoadingHome {
                            LearnErrorView(message: errorMessage) {
                                await learnVM.onTabAppear()
                                await learnVM.loadHome()
                            }
                            .padding(.horizontal, 20)
                        } else if learnVM.publishedWeeks.isEmpty && !learnVM.isLoadingHome {
                            VStack(spacing: 12) {
                                Text("📚")
                                    .font(.system(size: 48))
                                Text("No lessons yet")
                                    .font(.system(size: 20, design: .serif))
                                    .foregroundStyle(.white)
                                Text("Check back soon — content is being added.")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(Color(hex: "4B5563"))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            ForEach(learnVM.publishedWeeks) { week in
                                WeekRowCard(
                                    week: week,
                                    progress: learnVM.weekProgress(for: week.id ?? "")
                                )
                                .onTapGesture {
                                    guard learnVM.weekProgress(for: week.id ?? "")?.isUnlocked == true else { return }
                                    coordinator.push(.weekDetail(week.id ?? ""))
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }

            // ── Loading overlay ────────────────────────────────────────────
            if learnVM.isLoadingHome {
                LearnLoadingView()
            }
        }
        .navigationBarHidden(true)
        .task {
            await learnVM.onTabAppear()
            await learnVM.loadHome()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Learn")
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                Text("financial literacy")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            Spacer()
            // Streak badge
            VStack(spacing: 2) {
                Text("🔥")
                    .font(.title2)
                Text("\(learnVM.learningSummary.currentStreak)")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("streak")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            .padding(12)
            .background(Color(hex: "111118"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Daily Tip Card
struct DailyTipCard: View {
    let tip: DailyTip
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S INSIGHT")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "10B981"))
                Spacer()
                Text(tip.category.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            Text(tip.title)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(.white)

            if expanded {
                Text(tip.body)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button(expanded ? "Show less ↑" : "Read more ↓") {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            }
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Color(hex: "10B981"))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "0D1F17"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "10B981").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Continue Banner
struct ContinueBanner: View {
    let weekID: String
    let dayID: String
    let dayNumber: Int
    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @Environment(LearnViewModel.self)          private var learnVM

    var body: some View {
        Button {
            // Navigate to lesson for this day
            let days = learnVM.days(for: weekID)
            if let day = days.first(where: { $0.id == dayID }) {
                if day.isReflection {
                    let week = learnVM.publishedWeeks.first { $0.id == weekID }
                    coordinator.push(.reflection(weekID, week?.title ?? ""))
                } else {
                    coordinator.push(.lessonDetail(day.lessonID, dayID))
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CONTINUE WHERE YOU LEFT OFF")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                    Text("Day \(dayNumber)")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "111118"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "6366F1").opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Stats Strip
struct StatsStrip: View {
    let summary: LearningSummary

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(summary.totalLessonsRead)", label: "Lessons")
            Divider().frame(height: 30).background(Color(hex: "1F2937"))
            StatCell(value: "\(summary.totalQuizzesDone)", label: "Quizzes")
            Divider().frame(height: 30).background(Color(hex: "1F2937"))
            StatCell(value: String(format: "%.0f%%", summary.averageQuizScore), label: "Avg Score")
            Divider().frame(height: 30).background(Color(hex: "1F2937"))
            StatCell(value: summary.learningLevel.rawValue, label: "Level", small: true)
        }
        .padding(.vertical, 16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "1F2937"), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

struct StatCell: View {
    let value: String
    let label: String
    var small: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: small ? 12 : 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week Row Card
struct WeekRowCard: View {
    let week: Week
    let progress: WeekProgress?

    private var isLocked: Bool    { progress?.isUnlocked != true }
    private var isComplete: Bool  { progress?.isCompleted == true }

    var body: some View {
        HStack(spacing: 16) {
            // Week number circle
            ZStack {
                Circle()
                    .fill(isComplete ? Color(hex: "10B981") : isLocked ? Color(hex: "1F2937") : Color(hex: "6366F1").opacity(0.2))
                    .frame(width: 44, height: 44)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "374151"))
                } else {
                    Text("\(week.weekNumber)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(week.title)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(isLocked ? Color(hex: "374151") : .white)
                Text(week.description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(hex: "4B5563"))
                    .lineLimit(1)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "374151"))
            }
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isComplete ? Color(hex: "10B981").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
        .opacity(isLocked ? 0.5 : 1)
        .padding(.horizontal, 20)
    }
}

// MARK: - Loading
struct LearnLoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").opacity(0.8).ignoresSafeArea()
            ProgressView()
                .tint(Color(hex: "6366F1"))
                .scaleEffect(1.3)
        }
    }
}
