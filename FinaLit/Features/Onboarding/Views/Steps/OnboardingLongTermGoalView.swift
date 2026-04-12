//
//  OnboardingLongTermGoalView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingLongTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        String(localized: "onboarding.goalBuyHome"),
        String(localized: "onboarding.goalFinancialIndependence"),
        String(localized: "onboarding.goalPortfolio"),
        String(localized: "onboarding.goalStartBusiness"),
        String(localized: "onboarding.goalRetireEarly")
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .longTermGoal,
            title: String(localized: "onboarding.longTermGoal"),
            subtitle: String(localized: "onboarding.longTermSubtitle"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
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

                TextField(L10n.Profile.typeYourLongtermGoal, text: $viewModel.longTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.longTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}
