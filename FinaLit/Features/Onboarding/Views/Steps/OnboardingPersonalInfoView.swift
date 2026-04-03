//
//  OnboardingPersonalInfoView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingPersonalInfoView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    private let countries = [
        "Azerbaijan", "Turkey", "United States", "Canada", "United Kingdom", "Germany"
    ]

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .personalInfo,
            title: "Tell us about you",
            subtitle: "We use this to personalize your financial assistant.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep1Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep1PersonalInfo() {
                        coordinator.push(.employmentStatus)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .onboardingFieldLabelStyle()
                    TextField("Your name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Age")
                            .onboardingFieldLabelStyle()
                        Spacer()
                        Text("\(Int(viewModel.age.rounded()))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnboardingPalette.accent)
                    }
                    Slider(value: $viewModel.age, in: 13...70, step: 1)
                        .tint(OnboardingPalette.accent)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Country")
                        .onboardingFieldLabelStyle()

                    AdaptiveChips(
                        items: countries,
                        selection: viewModel.country,
                        onTap: { country in
                            viewModel.country = country
                            viewModel.clearError()
                        }
                    )

                    TextField("Or enter your country", text: $viewModel.country)
                        .textInputAutocapitalization(.words)
                        .onboardingInputStyle()
                }
            }
            .onChange(of: viewModel.name) { _, _ in viewModel.clearError() }
            .onChange(of: viewModel.country) { _, _ in viewModel.clearError() }
        }
    }
}
