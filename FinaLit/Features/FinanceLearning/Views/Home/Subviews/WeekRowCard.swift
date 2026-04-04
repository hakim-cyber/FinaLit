//
//  WeekRowCard.swift
//  FinaLit
//

import SwiftUI

struct WeekRowCard: View {
    let week: Week
    let progress: WeekProgress?

    private var isLocked: Bool { progress?.isUnlocked != true }
    private var isComplete: Bool { progress?.isCompleted == true }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        isComplete
                            ? AppTheme.success
                            : isLocked
                                ? AppTheme.surfaceSecondary
                                : AppTheme.softFill(for: .accent)
                    )
                    .frame(width: 44, height: 44)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.inverseText)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    Text("\(week.weekNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(week.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLocked ? AppTheme.textTertiary : AppTheme.textPrimary)
                Text(week.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
        .opacity(isLocked ? 0.65 : 1)
        .padding(.horizontal, 20)
    }
}
