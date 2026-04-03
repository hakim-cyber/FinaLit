//
//  GoalContributionSheet.swift
//  FinaLit
//

import SwiftUI

struct GoalContributionSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    let onAddGoal: () -> Void
    @State private var selectedGoalID: String = ""
    @State private var amount: String = ""
    @State private var showGoalPicker = false

    init(onAddGoal: @escaping () -> Void = {}) {
        self.onAddGoal = onAddGoal
    }

    private var selectedGoal: FinancialGoal? {
        mainVM.activeGoals.first(where: { $0.id == selectedGoalID }) ?? mainVM.activeGoals.first
    }

    private var parsedAmount: Double? { parseMonetaryInput(amount) }

    private var isValid: Bool {
        guard let value = parsedAmount, value > 0, selectedGoal != nil else { return false }
        return true
    }

    private func openAddGoal() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAddGoal()
        }
    }

    private func submitContribution() {
        guard let goal = selectedGoal, let value = parsedAmount else { return }
        Task {
            let saved = await mainVM.contributeToGoal(goal: goal, amount: value)
            if saved { dismiss() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    goalSection

                    if mainVM.activeGoals.isEmpty {
                        Text("Create a goal first to add a contribution.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONTRIBUTION")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    if let goal = selectedGoal {
                        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
                        Text("Remaining: \(formatCurrency(remaining))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Add to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { submitContribution() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
        .onAppear {
            if selectedGoalID.isEmpty {
                selectedGoalID = mainVM.activeGoals.first?.id ?? ""
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GOAL")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeGoals.isEmpty else { return }
                    showGoalPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedGoal?.title ?? "No goal selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Text(goalSubtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(mainVM.activeGoals.isEmpty ? Color(hex: "374151") : Color(hex: "9CA3AF"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "111118"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "1F2937"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(mainVM.activeGoals.isEmpty)
                .popover(isPresented: $showGoalPicker, arrowEdge: .top) {
                    goalPickerPopover
                        .presentationCompactAdaptation(.popover)
                }

                Button {
                    openAddGoal()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "6366F1").opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "6366F1").opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var goalSubtitle: String {
        guard let goal = selectedGoal else { return "Tap + to create a goal" }
        return "\(Int(goal.progressPercentage.rounded()))% funded • \(formatCurrency(max(goal.targetAmount - goal.currentAmount, 0))) left"
    }

    private var goalPickerPopover: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Goal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                ForEach(mainVM.activeGoals) { goal in
                    Button {
                        selectedGoalID = goal.id ?? ""
                        showGoalPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Text("\(Int(goal.progressPercentage.rounded()))% funded • \(formatCurrency(max(goal.targetAmount - goal.currentAmount, 0))) left")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }

                            Spacer()

                            if goal.id == selectedGoal?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "6366F1"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: goal.id == selectedGoal?.id ? "171724" : "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(hex: goal.id == selectedGoal?.id ? "6366F1" : "1F2937").opacity(goal.id == selectedGoal?.id ? 0.35 : 1),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(Color(hex: "0A0A0F"))
    }
}
