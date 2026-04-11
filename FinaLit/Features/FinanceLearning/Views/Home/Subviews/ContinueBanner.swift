//
//  ContinueBanner.swift
//  FinaLit
//

import SwiftUI

struct ContinueBanner: View {
    let weekID: String
    let dayID: String
    let dayNumber: Int

    @Environment(Coordinator<LearnPages>.self) private var coordinator
    @Environment(LearnViewModel.self) private var learnVM

    var body: some View {
        Button {
            let days = learnVM.days(for: weekID)
            if let day = days.first(where: { $0.id == dayID }) {
                if day.isReflection {
                    let week = learnVM.publishedWeeks.first { $0.id == weekID }
                    coordinator.push(.reflection(weekID, week?.title ?? ""))
                } else {
                    coordinator.push(.lessonDetail(day.lessonID, dayID, weekID))
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue where you left off")
                        .font(AppTheme.Typography.detail.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    Text("Day \(dayNumber)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .appSurface(.primary, padding: 20, cornerRadius: AppTheme.CornerRadius.large)
        }
        .padding(.horizontal, 20)
        .buttonStyle(.plain)
    }
}
