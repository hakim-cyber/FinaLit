//
//  OnboardingRiskInterestView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingRiskInterestView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .riskAndInvesting,
            title: "Risk and investing interest",
            subtitle: "We'll keep recommendations aligned with your comfort level.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep7Risk() {
                        coordinator.push(.shortTermGoal)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Risk tolerance")
                    .onboardingFieldLabelStyle()

                VStack(spacing: 10) {
                    RiskSelectionCard(
                        title: "Low",
                        subtitle: "Safety first, steady progress",
                        isSelected: viewModel.riskTolerance == .low,
                        tint: .green
                    ) {
                        viewModel.riskTolerance = .low
                        viewModel.clearError()
                    }

                    RiskSelectionCard(
                        title: "Medium",
                        subtitle: "Balanced risk and growth",
                        isSelected: viewModel.riskTolerance == .medium,
                        tint: .orange
                    ) {
                        viewModel.riskTolerance = .medium
                        viewModel.clearError()
                    }

                    RiskSelectionCard(
                        title: "High",
                        subtitle: "Higher volatility for higher potential",
                        isSelected: viewModel.riskTolerance == .high,
                        tint: .red
                    ) {
                        viewModel.riskTolerance = .high
                        viewModel.clearError()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Interested in investing?")
                        .onboardingFieldLabelStyle()

                    HStack(spacing: 10) {
                        TogglePill(title: "Yes", isSelected: viewModel.interestedInInvesting, tint: OnboardingPalette.accent) {
                            viewModel.interestedInInvesting = true
                            viewModel.clearError()
                        }
                        TogglePill(title: "Not now", isSelected: !viewModel.interestedInInvesting, tint: OnboardingPalette.muted) {
                            viewModel.interestedInInvesting = false
                            viewModel.clearError()
                        }
                    }
                }
            }
        }
    }
}
