//
//  SpendingHistoryChart.swift
//  FinaLit
//

import SwiftUI

struct SpendingHistoryChart: View {
    let snapshots: [MonthlySnapshot]

    private var maxExpense: Double {
        snapshots.map { $0.totalExpenses }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(snapshots) { snapshot in
                    VStack(spacing: 6) {
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        height: maxExpense > 0
                                            ? geometry.size.height * CGFloat(snapshot.totalExpenses / maxExpense)
                                            : 4
                                    )
                            }
                        }
                        Text(String(snapshot.month.suffix(2)))
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                }
            }
            .frame(height: 80)

            HStack {
                Text(formatCurrency(0))
                Spacer()
                Text(formatCurrency(maxExpense))
            }
            .font(.system(size: 9))
            .foregroundStyle(Color(hex: "374151"))
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
