//
//  OnboardingDebtView.swift
//  FinaLit
//

import SwiftUI

struct OnboardingDebtView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(Coordinator<OnboardingPages>.self) private var coordinator

    var body: some View {
        OnboardingStepScaffold(
            page: .debt,
            title: "Do you currently have debt?",
            subtitle: "We use this to balance payoff strategy with savings goals.",
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: "Continue",
            isPrimaryEnabled: viewModel.isStep6Valid,
            onPrimaryTap: {
                Task {
                    if await viewModel.saveStep6Debt() {
                        coordinator.push(.riskAndInvesting)
                    }
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    TogglePill(title: "No debt", isSelected: !viewModel.hasDebt, tint: .green) {
                        viewModel.setHasDebt(false)
                    }

                    TogglePill(title: "I have debt", isSelected: viewModel.hasDebt, tint: .red) {
                        viewModel.setHasDebt(true)
                    }
                }

                if viewModel.hasDebt {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Debt accounts")
                            .onboardingFieldLabelStyle()

                        ForEach(viewModel.debtEntries) { debtEntry in
                            OnboardingDebtEntryCard(
                                accountName: Binding(
                                    get: { viewModel.debtEntryName(debtEntry.id) },
                                    set: { viewModel.updateDebtEntryName(debtEntry.id, value: $0) }
                                ),
                                amountText: Binding(
                                    get: { viewModel.debtEntryAmountText(debtEntry.id) },
                                    set: { viewModel.updateDebtEntryAmount(debtEntry.id, value: $0) }
                                ),
                                canDelete: viewModel.debtEntries.count > 1,
                                onDelete: { viewModel.removeDebtEntry(debtEntry.id) }
                            )
                        }

                        Button {
                            viewModel.addDebtEntry()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add another debt")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "F87171"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "F87171").opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Text("Total debt")
                                .onboardingFieldLabelStyle()
                            Spacer()
                            Text(currency(viewModel.totalDebtAmount))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(OnboardingPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(OnboardingPalette.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}
