//
//  ProgressStatCard.swift
//  FinaLit
//

import SwiftUI

struct ProgressStatCard: View {
    let value: String
    let label: String
    let icon: String
    let tone: AppTone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.tint(for: tone))
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(label)
                    .font(AppTheme.Typography.detail)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
