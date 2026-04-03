//
//  OnboardingExpensesView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingExpensesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .monthlyExpenses,
            title: "Monthly expenses",
            subtitle: "Split your recurring and flexible spending.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep4Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep4Expenses() {
                        coordinator.push(.savingsAndEmergencyFund)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                MoneySlider(
                    title: "Fixed expenses",
                    value: $viewModel.monthlyFixedExpenses,
                    range: 0...10000,
                    step: 25,
                    tint: OnboardingPalette.accent
                )

                MoneySlider(
                    title: "Variable expenses",
                    value: $viewModel.monthlyVariableExpenses,
                    range: 0...10000,
                    step: 25,
                    tint: .orange
                )
            }
        }
    }
}
