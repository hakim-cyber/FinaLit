//
//  WeekDetailView.swift
//  FinaLit
//

import SwiftUI

struct WeekDetailView: View {
    let weekID: String

    @Environment(LearnViewModel.self) private var learnVM
    @Environment(AppPreferencesStore.self) private var preferences
    @Environment(Coordinator<LearnPages>.self) private var coordinator

    private var week: Week? {
        learnVM.publishedWeeks.first { $0.id == weekID }
    }

    private var localizedWeek: Week? {
        week?.resolved(for: preferences.effectiveLearningLanguage)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if let localizedWeek {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(String(localized: "learning.weekPrefixUpper")) \(localizedWeek.weekNumber)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                            Text(localizedWeek.title)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(localizedWeek.description)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }

                    WeekProgressBar(weekID: weekID)

                    VStack(spacing: 10) {
                        if let errorMessage = learnVM.errorMessage,
                           learnVM.days(for: weekID).isEmpty {
                            LearnErrorView(message: errorMessage) {
                                await learnVM.loadWeek(weekID: weekID)
                            }
                        } else if learnVM.days(for: weekID).isEmpty {
                            Text(L10n.Common.daysComingSoon)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(40)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(learnVM.days(for: weekID)) { day in
                                DayRowCard(
                                    day: day,
                                    weekID: weekID,
                                    progress: learnVM.dayProgress(for: day.id ?? "", in: weekID)
                                )
                                .onTapGesture {
                                    handleDayTap(day: day)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LearningLanguageMenu()
            }
        }
        .task { await learnVM.loadWeek(weekID: weekID) }
    }

    private func handleDayTap(day: Day) {
        guard let dayID = day.id else { return }
        let progress = learnVM.dayProgress(for: dayID, in: weekID)
        guard progress?.isUnlocked == true else { return }

        if day.isReflection {
            guard learnVM.isReflectionUnlocked(weekID: weekID) else { return }
            coordinator.push(.reflection(weekID, week?.title ?? ""))
        } else {
            coordinator.push(.lessonDetail(day.lessonID, dayID, weekID))
        }
    }
}
