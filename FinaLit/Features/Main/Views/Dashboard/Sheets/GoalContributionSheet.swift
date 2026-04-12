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
                AppTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    goalSection

                    if mainVM.activeGoals.isEmpty {
                        Text(L10n.Main.createAGoalFirstToAddAContribution)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Main.contribution)
                            .appFieldLabelStyle()
                        TextField(L10n.Profile.zero, text: $amount)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .keyboardType(.decimalPad)
                            .tint(AppTheme.accent)
                            .padding(.vertical, 6)
                        Divider().background(AppTheme.separator)
                    }

                    if let goal = selectedGoal {
                        let remaining = max(goal.targetAmount - goal.currentAmount, 0)
                        Text("Remaining: \(formatCurrency(remaining))")
                            .font(AppTheme.Typography.detail)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 4)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .navigationTitle(L10n.Main.addToGoal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Profile.cancel) { dismiss() }
                        .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Main.add) { submitContribution() }
                        .bold()
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
            Text(L10n.Main.goal)
                .appFieldLabelStyle()

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeGoals.isEmpty else { return }
                    showGoalPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedGoal?.title ?? "No goal selected")
                                .font(AppTheme.Typography.bodySemibold)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(goalSubtitle)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(AppTheme.Typography.badgeIcon)
                            .foregroundStyle(mainVM.activeGoals.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary)
                    }
                    .appSurface(.primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .font(AppTheme.Typography.rowIcon)
                        .foregroundStyle(AppTheme.tint(for: .accent))
                        .frame(width: 48, height: 48)
                        .background(AppTheme.softFill(for: .accent))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.softBorder(for: .accent), lineWidth: 1)
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
                Text(L10n.Main.selectGoal)
                    .font(AppTheme.Typography.bodySemibold)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(mainVM.activeGoals) { goal in
                    Button {
                        selectedGoalID = goal.id ?? ""
                        showGoalPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(AppTheme.Typography.bodySemibold)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("\(Int(goal.progressPercentage.rounded()))% funded • \(formatCurrency(max(goal.targetAmount - goal.currentAmount, 0))) left")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            if goal.id == selectedGoal?.id {
                                Image(systemName: "checkmark")
                                    .font(AppTheme.Typography.compactRowIcon)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .appSurface(goal.id == selectedGoal?.id ? .tinted(.accent) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(AppTheme.background)
    }
}
