//
//  OnboardingShortTermGoalView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingShortTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        "Build a \(AppRegion.currencySymbol)1,000 emergency fund",
        "Pay off a credit card",
        "Save for a new laptop",
        "Save for a trip",
        "Reduce monthly overspending"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .shortTermGoal,
            title: "Your short-term goal",
            subtitle: "Pick one quickly or write your own.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep8Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep8ShortTermGoal() {
                        coordinator.push(.longTermGoal)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveChips(items: suggestions, selection: viewModel.shortTermGoal) { value in
                    viewModel.shortTermGoal = value
                    viewModel.clearError()
                }

                TextField("Type your short-term goal", text: $viewModel.shortTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.shortTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}
