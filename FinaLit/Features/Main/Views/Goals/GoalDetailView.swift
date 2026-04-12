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
            AppTheme.background.ignoresSafeArea()

            if let goal {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        GoalCard(goal: goal)
                            .padding(.horizontal, AppTheme.Spacing.screen)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.Main.addContribution)
                                .appFieldLabelStyle()
                                .padding(.horizontal, AppTheme.Spacing.screen)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text(AppRegion.currencySymbol)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(AppTheme.textSecondary)
                                    TextField(L10n.Main.contribution, text: $newAmount)
                                        .font(AppTheme.Typography.body)
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .keyboardType(.decimalPad)
                                        .tint(AppTheme.accent)
                                }
                                .appSurface(.primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)

                                Button(L10n.Main.add) {
                                    if let amount = parsedContributionAmount {
                                        Task {
                                            let saved = await mainVM.contributeToGoal(goal: goal, amount: amount)
                                            if saved { newAmount = "" }
                                        }
                                    }
                                }
                                .buttonStyle(AppFilledButtonStyle(tone: .accent, compact: true, fillsWidth: false))
                                .disabled((parsedContributionAmount ?? 0) <= 0)
                            }
                            .padding(.horizontal, AppTheme.Spacing.screen)
                        }

                        let remaining = goal.targetAmount - goal.currentAmount
                        if remaining > 0 {
                            HStack {
                                Text(L10n.Main.stillNeeded)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                                Text(formatDisplayCurrency(remaining))
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 32)
                        }

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(L10n.Main.deleteGoal)
                            }
                            .font(AppTheme.Typography.bodySemibold)
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.softFill(for: .danger))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        }
                        .padding(.horizontal, AppTheme.Spacing.screen)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            if goal != nil { newAmount = "" }
        }
        .navigationTitle(L10n.Main.goal)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Main.deleteGoal2, isPresented: $showDeleteAlert) {
            Button(L10n.Main.delete, role: .destructive) {
                Task {
                    if let goal { await mainVM.deleteGoal(goal) }
                    coordinator.pop()
                }
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Main.thisCannotBeUndone)
        }
    }
}
