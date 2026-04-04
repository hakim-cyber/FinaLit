//
//  EmptyGoalsPreviewCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyGoalsPreviewCard: View {
    let onCreateGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No active goals yet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Create your first goal and start tracking progress from your dashboard.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onCreateGoal) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create your first goal")
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
