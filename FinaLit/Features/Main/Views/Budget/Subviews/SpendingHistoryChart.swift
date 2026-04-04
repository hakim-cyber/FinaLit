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
                                    .fill(AppTheme.chartPrimary)
                                    .frame(
                                        height: maxExpense > 0
                                            ? geometry.size.height * CGFloat(snapshot.totalExpenses / maxExpense)
                                            : 4
                                    )
                            }
                        }
                        Text(String(snapshot.month.suffix(2)))
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .frame(height: 80)

            HStack {
                Text(formatDisplayCurrency(0))
                Spacer()
                Text(formatDisplayCurrency(maxExpense))
            }
            .font(AppTheme.Typography.detail)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .appSurface(.primary, padding: 16, cornerRadius: AppTheme.CornerRadius.large)
    }
}
