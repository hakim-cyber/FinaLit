//
//  TotalBudgetCard.swift
//  FinaLit
//

import SwiftUI

struct TotalBudgetCard: View {
    let spent: Double
    let totalLimit: Double

    private var usage: Double {
        guard totalLimit > 0 else { return 0 }
        return min(spent / totalLimit, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOTAL BUDGET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B5563"))
                Spacer()
                if totalLimit > 0 {
                    Text("\(formatCurrency(spent)) / \(formatCurrency(totalLimit))")
                        .font(.system(size: 13))
                        .foregroundStyle(spent > totalLimit ? Color(hex: "F87171") : .white)
                }
            }
            if totalLimit > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "1F2937"))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: spent > totalLimit
                                        ? [Color(hex: "F87171"), Color(hex: "F87171")]
                                        : [Color(hex: "6366F1"), Color(hex: "10B981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(usage), height: 6)
                    }
                }
                .frame(height: 6)
            } else {
                Text("Set limits above to track your total budget.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "374151"))
            }
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
