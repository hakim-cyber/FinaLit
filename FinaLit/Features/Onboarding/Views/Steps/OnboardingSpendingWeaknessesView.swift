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
            title: "Where do you overspend most?",
            subtitle: "Pick up to \(viewModel.maxWeaknessSelections).",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep10Valid,
            onPrimaryTap: {
                if viewModel.validateStep10Weaknesses() {
                    coordinator.push(.hobbies)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(viewModel.spendingWeaknesses.count)/\(viewModel.maxWeaknessSelections) selected")
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
