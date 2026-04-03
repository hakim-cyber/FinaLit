//
//  PayDebtSheet.swift
//  FinaLit
//

import SwiftUI

struct PayDebtSheet: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(\.dismiss) private var dismiss
    let onAddDebt: () -> Void
    @State private var selectedDebtID: String = ""
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var showDebtAccountPicker = false

    init(onAddDebt: @escaping () -> Void = {}) {
        self.onAddDebt = onAddDebt
    }

    private var selectedAccount: DebtAccount? {
        mainVM.activeDebtAccounts.first(where: { $0.id == selectedDebtID }) ?? mainVM.activeDebtAccounts.first
    }

    private var parsedAmount: Double? { parseMonetaryInput(amount) }

    private var isValid: Bool {
        guard let value = parsedAmount, value > 0, selectedAccount != nil else { return false }
        return true
    }

    private func openAddDebt() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAddDebt()
        }
    }

    private func submitPayment() {
        guard let account = selectedAccount, let value = parsedAmount else { return }
        Task {
            let paid = await mainVM.payDebt(account: account, amount: value, note: note)
            if paid { dismiss() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0F").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    debtAccountSection

                    if mainVM.activeDebtAccounts.isEmpty {
                        Text("Create a debt account first to record a payment.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("0", text: $amount)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                            .keyboardType(.decimalPad)
                            .tint(Color(hex: "6366F1"))
                            .padding(.vertical, 6)
                        Divider().background(Color(hex: "1F2937"))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "4B5563"))
                        TextField("Debt payment", text: $note)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "111118"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "1F2937"), lineWidth: 1))
                    }

                    Spacer(minLength: 4)
                }
                .padding(20)
            }
            .navigationTitle("Pay Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { submitPayment() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid || mainVM.isSubmitting)
                }
            }
        }
        .onAppear {
            if selectedDebtID.isEmpty {
                selectedDebtID = mainVM.activeDebtAccounts.first?.id ?? ""
            }
        }
    }

    private var debtAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeDebtAccounts.isEmpty else { return }
                    showDebtAccountPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedAccount?.name ?? "No debt account selected")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Text(selectedAccount.map { formatCurrency($0.currentBalance) } ?? "Tap + to create a debt account")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(mainVM.activeDebtAccounts.isEmpty ? Color(hex: "374151") : Color(hex: "9CA3AF"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "111118"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "1F2937"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(mainVM.activeDebtAccounts.isEmpty)
                .popover(isPresented: $showDebtAccountPicker, arrowEdge: .top) {
                    debtAccountPickerPopover
                        .presentationCompactAdaptation(.popover)
                }

                Button {
                    openAddDebt()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "F97316").opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "F97316").opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var debtAccountPickerPopover: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Debt Account")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                ForEach(mainVM.activeDebtAccounts) { account in
                    Button {
                        selectedDebtID = account.id ?? ""
                        showDebtAccountPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(formatCurrency(account.currentBalance))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }

                            Spacer()

                            if account.id == selectedAccount?.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "F97316"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: account.id == selectedAccount?.id ? "171724" : "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(hex: account.id == selectedAccount?.id ? "F97316" : "1F2937").opacity(account.id == selectedAccount?.id ? 0.35 : 1),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(Color(hex: "0A0A0F"))
    }
}
