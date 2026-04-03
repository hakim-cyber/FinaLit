//
//  DayRowCard.swift
//  FinaLit
//

import SwiftUI

struct DayRowCard: View {
    let day: Day
    let weekID: String
    let progress: DayProgress?

    private var isLocked: Bool { progress?.isUnlocked != true }
    private var isComplete: Bool { progress?.isFullyComplete == true }
    private var lessonDone: Bool { progress?.lessonRead == true }
    private var quizDone: Bool { progress?.quizCompleted == true }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBackground)
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(day.isReflection ? "Reflection Day" : "Day \(day.dayNumber)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isLocked ? Color(hex: "374151") : .white)
                    if day.isReflection {
                        Text("📝")
                            .font(.caption)
                    }
                }

                if !isLocked && !day.isReflection {
                    HStack(spacing: 10) {
                        StatusDot(done: lessonDone, label: "Lesson")
                        StatusDot(done: quizDone, label: "Quiz")
                    }
                } else if day.isReflection {
                    Text(isLocked ? "Complete all days first" : "Write your week reflection")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "4B5563"))
                }

                if let score = progress?.quizScore,
                   let total = progress?.totalQuestions,
                   quizDone {
                    Text("\(score)/\(total) correct")
                        .font(.system(size: 11))
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
        if isLocked { return "lock.fill" }
        if day.isReflection { return isComplete ? "checkmark" : "pencil" }
        if isComplete { return "checkmark" }
        if lessonDone { return "questionmark.circle" }
        return "book"
    }

    private var iconBackground: Color {
        if isComplete { return Color(hex: "10B981").opacity(0.15) }
        if lessonDone { return Color(hex: "FACC15").opacity(0.15) }
        if isLocked { return Color(hex: "1F2937") }
        return Color(hex: "6366F1").opacity(0.15)
    }

    private var iconColor: Color {
        if isComplete { return Color(hex: "10B981") }
        if lessonDone { return Color(hex: "FACC15") }
        if isLocked { return Color(hex: "374151") }
        return Color(hex: "6366F1")
    }

    private var borderColor: Color {
        if isComplete { return Color(hex: "10B981").opacity(0.3) }
        if lessonDone { return Color(hex: "FACC15").opacity(0.2) }
        return Color(hex: "1F2937")
    }
}
