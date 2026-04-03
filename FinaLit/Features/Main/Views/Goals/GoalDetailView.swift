//
//  GoalDetailView.swift
//  FinaLit
//

import SwiftUI

struct GoalDetailView: View {
    let goalID: String

    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var newAmount: String = ""
    @State private var showDeleteAlert = false

    private var parsedContributionAmount: Double? {
        parseMonetaryInput(newAmount)
    }

    private var goal: FinancialGoal? {
        mainVM.goals.first { $0.id == goalID }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if let goal {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        GoalCard(goal: goal)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADD CONTRIBUTION")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text(AppRegion.currencySymbol)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(hex: "4B5563"))
                                    TextField("Contribution", text: $newAmount)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .keyboardType(.decimalPad)
                                        .tint(Color(hex: "6366F1"))
                                }
                                .padding(14)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "1F2937"), lineWidth: 1)
                                )

                                Button("Add") {
                                    if let amount = parsedContributionAmount {
                                        Task {
                                            let saved = await mainVM.contributeToGoal(goal: goal, amount: amount)
                                            if saved { newAmount = "" }
                                        }
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(hex: "6366F1"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .disabled((parsedContributionAmount ?? 0) <= 0)
                            }
                            .padding(.horizontal, 20)
                        }

                        let remaining = goal.targetAmount - goal.currentAmount
                        if remaining > 0 {
                            HStack {
                                Text("Still needed:")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "4B5563"))
                                Spacer()
                                Text(formatCurrency(remaining))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "6366F1"))
                            }
                            .padding(.horizontal, 32)
                        }

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Goal")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "F87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F87171").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            if goal != nil { newAmount = "" }
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Goal?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if let goal { await mainVM.deleteGoal(goal) }
                    coordinator.pop()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}
