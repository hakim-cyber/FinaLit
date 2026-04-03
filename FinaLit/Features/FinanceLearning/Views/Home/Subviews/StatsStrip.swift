//
//  StatsStrip.swift
//  FinaLit
//

import SwiftUI

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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
