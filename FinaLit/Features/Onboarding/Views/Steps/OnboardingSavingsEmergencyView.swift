//
//  OnboardingSavingsEmergencyView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingSavingsEmergencyView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        @Bindable var viewModel = viewModel

        OnboardingStepScaffold(
            page: .savingsAndEmergencyFund,
            title: String(localized: "onboarding.savingsEmergency"),
            subtitle: String(localized: "onboarding.savingsSubtitle"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
            isPrimaryEnabled: true,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep5Savings() {
                        coordinator.push(.debt)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MoneySlider(
                    title: String(localized: "main.savings"),
                    value: $viewModel.currentSavings,
                    range: 0...200000,
                    step: 100,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Onboarding.emergencyFund)
                        .onboardingFieldLabelStyle()

                    HStack {
                        Text(L10n.Onboarding.monthsCovered)
                            .foregroundStyle(OnboardingPalette.muted)
                        Spacer()
                        Stepper(value: $viewModel.emergencyFundMonths, in: 0...24) {
                            Text(String(format: NSLocalizedString("onboarding.emergencyMonths", comment: ""), viewModel.emergencyFundMonths))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .padding(14)
                    .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(OnboardingPalette.border, lineWidth: 1)
                    )
                }
            }
        }
    }
}
