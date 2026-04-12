//
//  OnboardingEmploymentStatusView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingEmploymentStatusView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .employmentStatus,
            title: "What's your employment status?",
            subtitle: "This helps us estimate realistic monthly cash flow.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep2Employment() {
                        coordinator.push(.incomeAndStability)
                    }
                }
            }
        ) {
            VStack(spacing: 10) {
                ForEach(EmploymentStatus.allCases) { status in
                    SelectableRowCard(
                        title: status.localizedName,
                        subtitle: status.description,
                        isSelected: viewModel.employmentStatus == status,
                        accent: OnboardingPalette.accent,
                        icon: "briefcase.fill"
                    ) {
                        viewModel.employmentStatus = status
                        viewModel.clearError()
                    }
                }
            }
        }
    }
}
