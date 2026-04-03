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
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACCOUNT NAME")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("e.g. Credit Card", text: $accountName)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CURRENT BALANCE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $balance)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APR % (OPTIONAL)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                            TextField("e.g. 19.9", text: $annualInterestRate)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("MIN PAYMENT (OPTIONAL)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B5563"))
                            TextField("e.g. 50", text: $minimumPayment)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color(hex: "111118"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                        }
                    }
                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Add Debt Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveDebtAccount() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
    }
}
