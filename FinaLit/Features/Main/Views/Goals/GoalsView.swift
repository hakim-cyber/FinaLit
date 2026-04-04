//
//  GoalsView.swift
//  FinaLit
//

import SwiftUI

struct GoalsView: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if mainVM.activeGoals.isEmpty {
                        EmptyGoalsCard()
                            .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            AppSectionHeader(title: "Active goals")

                            ForEach(mainVM.activeGoals) { goal in
                                GoalCard(goal: goal)
                                    .onTapGesture {
                                        coordinator.push(.goalDetail(goal.id ?? ""))
                                    }
                            }
                        }
                    }

                    if !mainVM.completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            AppSectionHeader(title: "Completed")

                            ForEach(mainVM.completedGoals) { goal in
                                GoalCard(goal: goal, isCompleted: true)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppTheme.Spacing.screen)
                .padding(.top, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    coordinator.push(.addGoal)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("New Goal")
                    }
                    .padding(.horizontal, 18)
                }
                .buttonStyle(AppFilledButtonStyle(tone: .accent, compact: true, fillsWidth: false))
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(AppTheme.background.opacity(0.94))
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}
