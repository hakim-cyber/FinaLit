//
//  OnboardingShortTermGoalView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingShortTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let suggestions = [
        String(format: NSLocalizedString("onboarding.suggestionEmergencyFund", comment: ""), AppRegion.currencySymbol),
        String(localized: "onboarding.suggestionPayOffCreditCard"),
        String(localized: "onboarding.suggestionSaveLaptop"),
        String(localized: "onboarding.suggestionSaveTrip"),
        String(localized: "onboarding.suggestionReduceOverspending")
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .shortTermGoal,
            title: String(localized: "onboarding.shortTermGoal"),
            subtitle: String(localized: "onboarding.shortTermSubtitle"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
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

                TextField(L10n.Profile.typeYourShorttermGoal, text: $viewModel.shortTermGoal, axis: .vertical)
                    .lineLimit(2...4)
                    .onboardingTextAreaStyle()
                    .onChange(of: viewModel.shortTermGoal) { _, _ in viewModel.clearError() }
            }
        }
    }
}
