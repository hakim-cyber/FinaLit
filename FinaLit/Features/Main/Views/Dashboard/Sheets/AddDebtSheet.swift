//
//  AddDebtSheet.swift
//  FinaLit
//

import SwiftUI

struct AddDebtSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    @State private var accountName: String = ""
    @State private var balance: String = ""
    @State private var annualInterestRate: String = ""
    @State private var minimumPayment: String = ""

    private var parsedBalance: Double? { parseMonetaryInput(balance) }
    private var parsedAPR: Double? { parseMonetaryInput(annualInterestRate) }
    private var parsedMinimumPayment: Double? { parseMonetaryInput(minimumPayment) }

    private var normalizedAPR: Double? {
        guard !annualInterestRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let parsedAPR, parsedAPR >= 0 else { return nil }
        return min(parsedAPR, 100)
    }

    private var normalizedMinimumPayment: Double? {
        guard !minimumPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let parsedMinimumPayment, parsedMinimumPayment > 0 else { return nil }
        return parsedMinimumPayment
    }

    private var isValid: Bool {
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (parsedBalance ?? 0) > 0
    }

    private func saveDebtAccount() {
        guard let value = parsedBalance else { return }
        Task {
            let saved = await mainVM.addDebtAccount(
                name: accountName,
                balance: value,
                annualInterestRate: normalizedAPR,
                minimumMonthlyPayment: normalizedMinimumPayment
            )
            if saved { dismiss() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account name")
                            .appFieldLabelStyle()
                        TextField("e.g. Credit Card", text: $accountName)
                            .appInputStyle()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current balance")
                            .appFieldLabelStyle()
                        TextField("0", text: $balance)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .keyboardType(.decimalPad)
                            .tint(AppTheme.accent)
                            .padding(.vertical, 6)
                        Divider().background(AppTheme.separator)
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APR % (optional)")
                                .appFieldLabelStyle()
                            TextField("e.g. 19.9", text: $annualInterestRate)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .keyboardType(.decimalPad)
                                .appInputStyle()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Min payment (optional)")
                                .appFieldLabelStyle()
                            TextField("e.g. 50", text: $minimumPayment)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.textPrimary)
                                .keyboardType(.decimalPad)
                                .appInputStyle()
                        }
                    }
                    Spacer(minLength: 4)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .navigationTitle("Add Debt Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveDebtAccount() }
                        .foregroundStyle(Color.orange)
                        .bold()
                        .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
    }
}
