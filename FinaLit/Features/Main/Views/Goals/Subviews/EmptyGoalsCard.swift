//
//  EmptyGoalsCard.swift
//  FinaLit
//

import SwiftUI

struct EmptyGoalsCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("🎯")
                .font(.system(size: 40))
            Text("No goals yet")
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Set a financial goal to track your progress.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appSurface(.primary, padding: 40, cornerRadius: AppTheme.CornerRadius.large)
    }
}
