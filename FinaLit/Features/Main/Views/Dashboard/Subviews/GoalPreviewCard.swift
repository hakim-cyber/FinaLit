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
        return "Need \(formatCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return Color(hex: "10B981") }
        return monthsUntilDeadline < 0 ? Color(hex: "F87171") : Color(hex: "10B981")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(String(format: "%.0f", goal.progressPercentage))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "6366F1"))
            }
            HStack {
                Text(formatCurrency(goal.currentAmount))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "9CA3AF"))
                Text("of \(formatCurrency(goal.targetAmount))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
            if let monthlyPaceText {
                Text(monthlyPaceText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(monthlyPaceColor)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(goal.progressPercentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "1F2937"), lineWidth: 1)
        )
    }
}
