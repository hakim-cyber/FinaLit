//
//  OnboardingSpendingWeaknessesView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingSpendingWeaknessesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        OnboardingStepScaffold(
            page: .spendingWeaknesses,
            title: String(localized: "onboarding.overspendMost"),
            subtitle: String(format: NSLocalizedString("onboarding.pickUpToWeakness", comment: ""), viewModel.maxWeaknessSelections),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
            isPrimaryEnabled: viewModel.isStep10Valid,
            onPrimaryTap: {
                if viewModel.validateStep10Weaknesses() {
                    coordinator.push(.hobbies)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: NSLocalizedString("onboarding.selectedCount", comment: ""), viewModel.spendingWeaknesses.count, viewModel.maxWeaknessSelections))
                    .font(.system(size: 11))
                    .foregroundStyle(OnboardingPalette.muted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(SpendingCategory.allCases) { category in
                        let isSelected = viewModel.spendingWeaknesses.contains(category)
                        ChipButton(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: isSelected,
                            onTap: { viewModel.toggleWeakness(category) }
                        )
                    }
                }
            }
        }
    }
}
