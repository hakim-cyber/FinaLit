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
            title: "Savings and emergency buffer",
            subtitle: "A quick view of your safety net today.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
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
                    title: "Current savings",
                    value: $viewModel.currentSavings,
                    range: 0...200000,
                    step: 100,
                    tint: .green
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Emergency fund")
                        .onboardingFieldLabelStyle()

                    HStack {
                        Text("Months covered")
                            .foregroundStyle(OnboardingPalette.muted)
                        Spacer()
                        Stepper(value: $viewModel.emergencyFundMonths, in: 0...24) {
                            Text("\(viewModel.emergencyFundMonths) months")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
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
