//
//  CategoryRow.swift
//  FinaLit
//

import SwiftUI

struct CategoryRow: View {
    let category: TransactionCategory
    let amount: Double
    let total: Double
    let limit: Double?

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (amount / total) * 100
    }

    private var isOverBudget: Bool {
        guard let limit else { return false }
        return amount > limit
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: category.color))
                        .frame(width: 20)
                    Text(category.rawValue)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(amount))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isOverBudget ? Color(hex: "F87171") : .white)
                    if let limit {
                        Text("of \(formatCurrency(limit))")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "4B5563"))
                    } else {
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "1F2937"))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isOverBudget ? Color(hex: "F87171") : Color(hex: category.color))
                        .frame(
                            width: progressBarWidth(totalWidth: geometry.size.width),
                            height: 3
                        )
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isOverBudget ? Color(hex: "F87171").opacity(0.3) : Color(hex: "1F2937"),
                    lineWidth: 1
                )
        )
    }

    private func progressBarWidth(totalWidth: CGFloat) -> CGFloat {
        if let limit, limit > 0 {
            return min(totalWidth * CGFloat(amount / limit), totalWidth)
        }
        return totalWidth * CGFloat(percentage / 100)
    }
}
