//
//  GoalCard.swift
//  FinaLit
//

import SwiftUI

struct GoalCard: View {
    let goal: FinancialGoal
    var isCompleted: Bool = false

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
        guard !isCompleted, remainingAmount > 0, let monthsUntilDeadline else { return nil }
        guard monthsUntilDeadline >= 0 else { return "Deadline passed" }

        let monthWindow = max(monthsUntilDeadline, 1)
        let neededPerMonth = remainingAmount / Double(monthWindow)
        return "Need \(formatDisplayCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return AppTheme.textSecondary }
        return monthsUntilDeadline < 0 ? AppTheme.danger : AppTheme.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if let deadline = goal.deadline {
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .font(AppTheme.Typography.rowIcon)
                } else {
                    AppToneBadge(
                        title: "\(String(format: "%.0f", goal.progressPercentage))%",
                        systemImage: "target",
                        tone: .accent
                    )
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDisplayCurrency(goal.currentAmount))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .monospacedDigit()
                    Text("saved")
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDisplayCurrency(goal.targetAmount))
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("target")
                        .font(AppTheme.Typography.detail)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if let monthlyPaceText {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(AppTheme.Typography.badgeIcon)
                    Text(monthlyPaceText)
                        .font(AppTheme.Typography.detail.weight(.semibold))
                }
                .foregroundStyle(monthlyPaceColor)
            }

            AppThinProgressBar(progress: goal.progressPercentage / 100, tone: isCompleted ? .success : .accent)
        }
        .appSurface(isCompleted ? .tinted(.success) : .primary, padding: 18, cornerRadius: AppTheme.CornerRadius.large)
        .opacity(isCompleted ? 0.6 : 1)
    }
}
