//
//  DailyTipCard.swift
//  FinaLit
//

import SwiftUI

struct DailyTipCard: View {
    let tip: DailyTip
    @State private var expanded = false
    @Environment(AppPreferencesStore.self) private var preferences

    private var localizedTip: DailyTip {
        tip.resolved(for: preferences.effectiveLearningLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Common.todaysInsight)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.success)
                Spacer()
                Text(localizedTip.category.uppercased())
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(localizedTip.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if expanded {
                Text(localizedTip.body)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button(expanded ? "Show less ↑" : "Read more ↓") {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.success)
        }
        .appSurface(.primary, padding: 20, cornerRadius: AppTheme.CornerRadius.large)
        .padding(.horizontal, 20)
    }
}
