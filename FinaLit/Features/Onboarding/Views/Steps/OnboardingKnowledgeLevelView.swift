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
            title: "How would you rate your financial knowledge?",
            subtitle: "We'll adjust guidance depth and language to match.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Finish Setup",
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    _ = await viewModel.completeOnboarding()
                }
            }
        ) {
            VStack(spacing: 10) {
                KnowledgeLevelCard(
                    title: "Beginner",
                    description: "Simple, practical next steps",
                    level: 0.33,
                    isSelected: viewModel.knowledgeLevel == .beginner
                ) {
                    viewModel.knowledgeLevel = .beginner
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: "Intermediate",
                    description: "Balanced insights with more detail",
                    level: 0.66,
                    isSelected: viewModel.knowledgeLevel == .intermediate
                ) {
                    viewModel.knowledgeLevel = .intermediate
                    viewModel.clearError()
                }

                KnowledgeLevelCard(
                    title: "Advanced",
                    description: "Higher detail and analytical trade-offs",
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
