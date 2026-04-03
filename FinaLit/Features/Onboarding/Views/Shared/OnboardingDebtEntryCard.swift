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
                            .foregroundStyle(Color(hex: "F87171"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "450A0A"), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "7F1D1D"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Debt amount", text: $amountText)
                .keyboardType(.decimalPad)
                .onboardingInputStyle()
        }
        .padding(12)
        .background(OnboardingPalette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(OnboardingPalette.border, lineWidth: 1)
        )
    }
}
