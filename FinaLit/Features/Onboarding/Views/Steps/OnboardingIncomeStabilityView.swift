//
//  OnboardingIncomeStabilityView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingIncomeStabilityView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .incomeAndStability,
            title: String(localized: "onboarding.incomeStabilityHeader"),
            subtitle: String(localized: "onboarding.setMonthlyIncome"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
            isPrimaryEnabled: viewModel.isStep3Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep3Income() {
                        coordinator.push(.monthlyExpenses)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MoneySlider(
                    title: String(localized: "onboarding.monthlyIncome"),
                    value: $viewModel.monthlyIncome,
                    range: 0...20000,
                    step: 50,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Profile.incomeStability)
                        .onboardingFieldLabelStyle()

                    HStack(spacing: 10) {
                        TogglePill(
                            title: String(localized: "main.stabilityStable"),
                            isSelected: viewModel.incomeStability == .stable,
                            tint: OnboardingPalette.accent
                        ) {
                            viewModel.incomeStability = .stable
                            viewModel.clearError()
                        }

                        TogglePill(
                            title: String(localized: "onboarding.variable"),
                            isSelected: viewModel.incomeStability == .variable,
                            tint: .orange
                        ) {
                            viewModel.incomeStability = .variable
                            viewModel.clearError()
                        }
                    }
                }
            }
        }
    }
}
