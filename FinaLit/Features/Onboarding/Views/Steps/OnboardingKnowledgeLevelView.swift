//
//  OnboardingKnowledgeLevelView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingKnowledgeLevelView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        OnboardingStepScaffold(
            page: .knowledgeLevel,
            title: String(localized: "onboarding.rateKnowledge"),
            subtitle: String(localized: "onboarding.knowledgeSubtitle"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "onboarding.finishSetup"),
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    _ = await viewModel.completeOnboarding()
                }
            }
        ) {
            VStack(spacing: 10) {
                KnowledgeLevelCard(
                    title: String(localized: "onboarding.knowledgeBeginner"),
                    description: String(localized: "onboarding.knowledgeBeginnerDesc"),
                    level: 0.33,
                    isSelected: viewModel.knowledgeLevel == .beginner
                ) {
                    viewModel.knowledgeLevel = .beginner
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: String(localized: "onboarding.knowledgeIntermediate"),
                    description: String(localized: "onboarding.knowledgeIntermediateDesc"),
                    level: 0.66,
                    isSelected: viewModel.knowledgeLevel == .intermediate
                ) {
                    viewModel.knowledgeLevel = .intermediate
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: String(localized: "onboarding.knowledgeAdvanced"),
                    description: String(localized: "onboarding.knowledgeAdvancedDesc"),
                    level: 1.0,
                    isSelected: viewModel.knowledgeLevel == .advanced
                ) {
                    viewModel.knowledgeLevel = .advanced
                    viewModel.clearError()
                }
            }
        }
    }
}
