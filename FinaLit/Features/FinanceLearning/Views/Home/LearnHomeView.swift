//
//  LearnHomeView.swift
//  FinaLit
//

import SwiftUI

struct LearnHomeView: View {
    @Environment(LearnViewModel.self) private var learnVM
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    if let tip = learnVM.todaysTip {
                        DailyTipCard(tip: tip)
                    }

                    if let next = learnVM.nextUnlockedDay {
                        ContinueBanner(weekID: next.weekID, dayID: next.dayID, dayNumber: next.dayNumber)
                    }

                    StatsStrip(summary: learnVM.learningSummary)
                        .onTapGesture { coordinator.push(.progress) }

                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader(title: "Your curriculum")

                        if let errorMessage = learnVM.errorMessage,
                           learnVM.publishedWeeks.isEmpty,
                           !learnVM.isLoadingHome {
                            LearnErrorView(message: errorMessage) {
                                await learnVM.onTabAppear()
                                await learnVM.loadHome()
                            }
                            .padding(.horizontal, 20)
                        } else if learnVM.publishedWeeks.isEmpty && !learnVM.isLoadingHome {
                            VStack(spacing: 12) {
                                Text("📚")
                                    .font(.system(size: 48))
                                Text("No lessons yet")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Check back soon — content is being added.")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .appSurface(.primary, padding: 40, cornerRadius: AppTheme.CornerRadius.large)
                        } else {
                            ForEach(learnVM.publishedWeeks) { week in
                                WeekRowCard(
                                    week: week,
                                    progress: learnVM.weekProgress(for: week.id ?? "")
                                )
                                .onTapGesture {
                                    guard learnVM.weekProgress(for: week.id ?? "")?.isUnlocked == true else { return }
                                    coordinator.push(.weekDetail(week.id ?? ""))
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .refreshable {
                await learnVM.onTabAppear(force: true)
                await learnVM.loadHome(force: true)
            }

            if learnVM.isLoadingHome {
                LearnLoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.progress)
                } label: {
                    Image(systemName: "flame.fill")
                        .font(AppTheme.Typography.toolbarIcon)
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.settings, type: .fullScreenCover)
                } label: {
                    Image(systemName: "gearshape")
                        .font(AppTheme.Typography.toolbarIcon)
                }
            }
        }
        .task {
            await learnVM.onTabAppear()
            await learnVM.loadHome()
        }
    }
}
