//
//  OnboardingDebtEntryCard.swift
//  FinaLit
//

import SwiftUI

struct OnboardingDebtEntryCard: View {
    @Binding var accountName: String
    @Binding var amountText: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Debt account name", text: $accountName)
                    .textInputAutocapitalization(.words)
                    .onboardingInputStyle()

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.softFill(for: .danger), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.softBorder(for: .danger), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Debt amount", text: $amountText)
                .keyboardType(.decimalPad)
                .onboardingInputStyle()
        }
        .appSurface(.primary, padding: 12, cornerRadius: AppTheme.CornerRadius.medium)
    }
}
