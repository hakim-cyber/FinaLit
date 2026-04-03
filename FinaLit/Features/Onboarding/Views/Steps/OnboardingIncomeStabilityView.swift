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
            title: "Income and stability",
            subtitle: "Set your monthly income and tell us how consistent it is.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
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
                    title: "Monthly income",
                    value: $viewModel.monthlyIncome,
                    range: 0...20000,
                    step: 50,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Income stability")
                        .onboardingFieldLabelStyle()

                    HStack(spacing: 10) {
                        TogglePill(
                            title: "Stable",
                            isSelected: viewModel.incomeStability == .stable,
                            tint: OnboardingPalette.accent
                        ) {
                            viewModel.incomeStability = .stable
                            viewModel.clearError()
                        }

                        TogglePill(
                            title: "Variable",
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
