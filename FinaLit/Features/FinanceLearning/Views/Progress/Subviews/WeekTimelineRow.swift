//
//  WeekTimelineRow.swift
//  FinaLit
//

import SwiftUI

struct WeekTimelineRow: View {
    let weekProgress: WeekProgress
    let weekTitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(weekProgress.isCompleted ? AppTheme.success : AppTheme.separator)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(weekTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textPrimary)
                if let date = weekProgress.completedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSecondary)
                } else if weekProgress.isUnlocked {
                    Text("In progress")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.accent)
                } else {
                    Text("Locked")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Spacer()

            if weekProgress.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
                    .font(.system(size: 16))
            } else if weekProgress.isUnlocked {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(AppTheme.accent)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 20)
    }
}
