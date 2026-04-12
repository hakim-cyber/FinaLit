//
//  EmptyGoalsPreviewCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyGoalsPreviewCard: View {
    let onCreateGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Main.noActiveGoalsYet)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(L10n.Main.createYourFirstGoalAndStartTrackingProgressFromYourDashboard)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(L10n.Main.createYourFirstGoal)
                }
                .font(AppTheme.Typography.bodySemibold)
                .foregroundStyle(AppTheme.inverseText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.success)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
