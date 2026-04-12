//
//  InsightsView.swift
//  FinaLit
//

import SwiftUI

struct InsightsView: View {
    @Environment(MainViewModel.self) private var mainVM

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    if let summary = mainVM.summary {
                        VStack(alignment: .leading, spacing: 10) {
                            AppSectionHeader(title: L10n.Main.monthlyOverview)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 10
                            ) {
                                InsightStatCard(
                                    label: String(localized: "main.dailyAverage"),
                                    value: formatDisplayCurrency(summary.dailyAverage),
                                    icon: "calendar",
                                    tone: .accent
                                )
                                InsightStatCard(
                                    label: String(localized: "main.netBalance"),
                                    value: formatSignedDisplayCurrency(summary.monthlyNet),
                                    icon: "equal.circle.fill",
                                    tone: summary.monthlyNet >= 0 ? .success : .danger
                                )
                                InsightStatCard(
                                    label: String(localized: "main.discretionary"),
                                    value: "\(String(format: "%.0f", summary.discretionaryRatio * 100))%",
                                    icon: "bag.fill",
                                    tone: summary.discretionaryRatio > 0.3 ? .warning : .success
                                )
                                if let growth = summary.expenseGrowthRate {
                                    InsightStatCard(
                                        label: String(localized: "main.vsLastMonth"),
                                        value: "\(growth >= 0 ? "+" : "")\(String(format: "%.0f", growth))%",
                                        icon: growth >= 0 ? "arrow.up.right" : "arrow.down.right",
                                        tone: growth > 10 ? .danger : growth < -5 ? .success : .slate
                                    )
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        AppSectionHeader(title: L10n.Main.smartInsights)

                        if mainVM.insights.isEmpty {
                            VStack(spacing: 12) {
                                Text("✨")
                                    .font(.system(size: 36))
                                Text(L10n.Main.addTransactionsToSeeInsights)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .appSurface(.primary, padding: 32, cornerRadius: AppTheme.CornerRadius.large)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(mainVM.insights) { insight in
                                    InsightCard(insight: insight)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if !mainVM.recentSnapshots.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            AppSectionHeader(title: L10n.Main.spendingHistory)

                            SpendingHistoryChart(snapshots: mainVM.recentSnapshots)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, 16)
            }
        }
        .navigationTitle(L10n.Main.insights)
        .navigationBarTitleDisplayMode(.inline)
    }
}
