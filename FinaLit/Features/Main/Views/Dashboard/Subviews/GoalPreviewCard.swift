//
//  GoalPreviewCard.swift
//  FinaLit
//

import SwiftUI

struct GoalPreviewCard: View {
    let goal: FinancialGoal

    private var remainingAmount: Double {
        max(goal.targetAmount - goal.currentAmount, 0)
    }

    private var monthsUntilDeadline: Int? {
        guard let deadline = goal.deadline else { return nil }
        let calendar = Calendar.current
        let fromDate = calendar.startOfDay(for: Date())
        let toDate = calendar.startOfDay(for: deadline)
        return calendar.dateComponents([.month], from: fromDate, to: toDate).month
    }

    private var monthlyPaceText: String? {
        guard remainingAmount > 0, let monthsUntilDeadline else { return nil }
        guard monthsUntilDeadline >= 0 else { return "Deadline passed" }

        let neededPerMonth = remainingAmount / Double(max(monthsUntilDeadline, 1))
        return "Need \(formatDisplayCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return AppTheme.success }
        return monthsUntilDeadline < 0 ? AppTheme.danger : AppTheme.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(goal.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                AppToneBadge(
                    title: "\(String(format: "%.0f", goal.progressPercentage))%",
                    systemImage: "target",
                    tone: .accent
                )
            }
            HStack {
                Text(formatDisplayCurrency(goal.currentAmount))
                    .font(AppTheme.Typography.bodySemibold)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("of \(formatDisplayCurrency(goal.targetAmount))")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            if let monthlyPaceText {
                Text(monthlyPaceText)
                    .font(AppTheme.Typography.detail.weight(.semibold))
                    .foregroundStyle(monthlyPaceColor)
            }
            AppThinProgressBar(progress: goal.progressPercentage / 100, tone: .accent)
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
