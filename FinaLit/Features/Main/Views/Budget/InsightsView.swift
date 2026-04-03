//
//  InsightsView.swift
//  FinaLit
//

import SwiftUI

struct InsightsView: View {
    @Environment(MainViewModel.self) private var mainVM

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if let summary = mainVM.summary {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MONTHLY OVERVIEW")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 10
                            ) {
                                InsightStatCard(
                                    label: "Daily Average",
                                    value: formatCurrency(summary.dailyAverage),
                                    icon: "calendar",
                                    color: "6366F1"
                                )
                                InsightStatCard(
                                    label: "Net Balance",
                                    value: formatSignedCurrency(summary.monthlyNet),
                                    icon: "equal.circle.fill",
                                    color: summary.monthlyNet >= 0 ? "10B981" : "F87171"
                                )
                                InsightStatCard(
                                    label: "Discretionary",
                                    value: "\(String(format: "%.0f", summary.discretionaryRatio * 100))%",
                                    icon: "bag.fill",
                                    color: summary.discretionaryRatio > 0.3 ? "FACC15" : "10B981"
                                )
                                if let growth = summary.expenseGrowthRate {
                                    InsightStatCard(
                                        label: "vs Last Month",
                                        value: "\(growth >= 0 ? "+" : "")\(String(format: "%.0f", growth))%",
                                        icon: growth >= 0 ? "arrow.up.right" : "arrow.down.right",
                                        color: growth > 10 ? "F87171" : growth < -5 ? "10B981" : "6B7280"
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("SMART INSIGHTS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                            .padding(.horizontal, 20)

                        if mainVM.insights.isEmpty {
                            VStack(spacing: 12) {
                                Text("✨")
                                    .font(.system(size: 36))
                                Text("Add transactions to see insights")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: "374151"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(32)
                        } else {
                            ForEach(mainVM.insights) { insight in
                                InsightCard(insight: insight)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    if !mainVM.recentSnapshots.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SPENDING HISTORY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            SpendingHistoryChart(snapshots: mainVM.recentSnapshots)
                                .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
