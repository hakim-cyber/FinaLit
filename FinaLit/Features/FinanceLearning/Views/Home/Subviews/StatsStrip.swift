//
//  StatsStrip.swift
//  FinaLit
//

import SwiftUI

struct StatsStrip: View {
    let summary: LearningSummary

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(summary.totalLessonsRead)", label: String(localized: "learning.lessons"))
            Divider().frame(height: 30).background(AppTheme.separator)
            StatCell(value: "\(summary.totalQuizzesDone)", label: String(localized: "learning.quizzes"))
            Divider().frame(height: 30).background(AppTheme.separator)
            StatCell(value: String(format: "%.0f%%", summary.averageQuizScore), label: String(localized: "learning.avgScore"))
            Divider().frame(height: 30).background(AppTheme.separator)
            StatCell(value: summary.learningLevel.rawValue, label: String(localized: "learning.level"), small: true)
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
        .padding(.horizontal, 20)
    }
}
