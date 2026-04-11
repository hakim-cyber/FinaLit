//
//  DayRowCard.swift
//  FinaLit
//

import SwiftUI

struct DayRowCard: View {
    let day: Day
    let weekID: String
    let progress: DayProgress?
    @Environment(AppPreferencesStore.self) private var preferences

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
                    Text(day.isReflection ? "Reflection Day" : L10n.tr("Day %@", preferences: preferences, String(day.dayNumber)))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isLocked ? AppTheme.textTertiary : AppTheme.textPrimary)
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
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if let score = progress?.quizScore,
                   let total = progress?.totalQuestions,
                   quizDone {
                    Text(L10n.tr("%@/%@ correct", preferences: preferences, String(score), String(total)))
                        .font(.system(size: 11))
                        .foregroundStyle(progress?.isPassed == true ? AppTheme.success : AppTheme.danger)
                }
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(14)
        .background(AppTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 1)
        )
        .opacity(isLocked ? 0.6 : 1)
    }

    private var iconName: String {
        if isLocked { return "lock.fill" }
        if day.isReflection { return isComplete ? "checkmark" : "pencil" }
        if isComplete { return "checkmark" }
        if lessonDone { return "questionmark.circle" }
        return "book"
    }

    private var iconBackground: Color {
        if isComplete { return AppTheme.success.opacity(0.15) }
        if lessonDone { return AppTheme.warning.opacity(0.15) }
        if isLocked { return AppTheme.separator }
        return AppTheme.accent.opacity(0.15)
    }

    private var iconColor: Color {
        if isComplete { return AppTheme.success }
        if lessonDone { return AppTheme.warning }
        if isLocked { return AppTheme.textTertiary }
        return AppTheme.accent
    }

    private var borderColor: Color {
        if isComplete { return AppTheme.success.opacity(0.3) }
        if lessonDone { return AppTheme.warning.opacity(0.2) }
        return AppTheme.separator
    }
}
