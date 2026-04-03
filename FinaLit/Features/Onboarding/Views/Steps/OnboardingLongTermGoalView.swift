//
//  OnboardingLongTermGoalView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingLongTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        "Buy a home",
        "Reach financial independence",
        "Build a 6-figure portfolio",
        "Start a business",
        "Retire early"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .longTermGoal,
            title: "Your long-term goal",
            subtitle: "This guides strategic recommendations over time.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep9Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep9LongTermGoal() {
                        coordinator.push(.spendingWeaknesses)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveChips(items: suggestions, selection: viewModel.longTermGoal) { value in
                    viewModel.longTermGoal = value
                    viewModel.clearError()
                }

                TextField("Type your long-term goal", text: $viewModel.longTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.longTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}
