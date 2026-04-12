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
            title: String(localized: "onboarding.haveDebt"),
            subtitle: String(localized: "onboarding.debtSubtitle"),
            errorMessage: viewModel.errorMessage,
            isLoading: viewModel.isLoading,
            primaryTitle: String(localized: "profile.continueAction"),
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
                    TogglePill(title: String(localized: "profile.noDebt"), isSelected: !viewModel.hasDebt, tint: .green) {
                        viewModel.setHasDebt(false)
                    }

                    TogglePill(title: String(localized: "profile.haveDebt"), isSelected: viewModel.hasDebt, tint: .red) {
                        viewModel.setHasDebt(true)
                    }
                }

                if viewModel.hasDebt {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.Onboarding.debtAccounts)
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
                                Text(L10n.Onboarding.addAnotherDebt)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.softFill(for: .danger))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Text(L10n.Onboarding.totalDebt)
                                .onboardingFieldLabelStyle()
                            Spacer()
                            Text(currency(viewModel.totalDebtAmount))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .appSurface(.primary, padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
                    }
                }
            }
        }
    }
}
