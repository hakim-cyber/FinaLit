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
        return "Need \(formatCurrency(neededPerMonth))/month"
    }

    private var monthlyPaceColor: Color {
        guard let monthsUntilDeadline else { return Color(hex: "4B5563") }
        return monthsUntilDeadline < 0 ? Color(hex: "F87171") : Color(hex: "10B981")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    if let deadline = goal.deadline {
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "10B981"))
                        .font(.system(size: 20))
                } else {
                    Text("\(String(format: "%.0f", goal.progressPercentage))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatCurrency(goal.currentAmount))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                    Text("saved")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(goal.targetAmount))
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Text("target")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
            }

            if let monthlyPaceText {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 10))
                    Text(monthlyPaceText)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(monthlyPaceColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isCompleted
                                ? LinearGradient(
                                    colors: [Color(hex: "10B981"), Color(hex: "10B981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "10B981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: geometry.size.width * CGFloat(goal.progressPercentage / 100), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: goal.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCompleted ? Color(hex: "10B981").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
        .opacity(isCompleted ? 0.6 : 1)
    }
}
