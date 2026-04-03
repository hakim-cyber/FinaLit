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
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if mainVM.activeGoals.isEmpty {
                        EmptyGoalsCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACTIVE GOALS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            ForEach(mainVM.activeGoals) { goal in
                                GoalCard(goal: goal)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        coordinator.push(.goalDetail(goal.id ?? ""))
                                    }
                            }
                        }
                    }

                    if !mainVM.completedGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("COMPLETED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            ForEach(mainVM.completedGoals) { goal in
                                GoalCard(goal: goal, isCompleted: true)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        coordinator.push(.addGoal)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New Goal")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 10, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}
