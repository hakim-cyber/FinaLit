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
                AppTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    debtAccountSection

                    if mainVM.activeDebtAccounts.isEmpty {
                        Text(L10n.Main.createADebtAccountFirstToRecordAPayment)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Main.amount)
                            .appFieldLabelStyle()
                        TextField(L10n.Profile.zero, text: $amount)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .keyboardType(.decimalPad)
                            .tint(AppTheme.accent)
                            .padding(.vertical, 6)
                        Divider().background(AppTheme.separator)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Main.noteOptional)
                            .appFieldLabelStyle()
                        TextField(L10n.Main.debtPayment, text: $note)
                            .appInputStyle()
                    }

                    Spacer(minLength: 4)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .navigationTitle(L10n.Main.payDebt)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Profile.cancel) { dismiss() }
                        .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Main.add) { submitPayment() }
                        .foregroundStyle(Color.orange)
                        .bold()
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
            Text(L10n.Main.account)
                .appFieldLabelStyle()

            HStack(spacing: 10) {
                Button {
                    guard !mainVM.activeDebtAccounts.isEmpty else { return }
                    showDebtAccountPicker = true
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedAccount?.name ?? "No debt account selected")
                                .font(AppTheme.Typography.bodySemibold)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(selectedAccount.map { formatCurrency($0.currentBalance) } ?? "Tap + to create a debt account")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(AppTheme.Typography.badgeIcon)
                            .foregroundStyle(mainVM.activeDebtAccounts.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary)
                    }
                    .appSurface(.primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .font(AppTheme.Typography.rowIcon)
                        .foregroundStyle(AppTheme.tint(for: .orange))
                        .frame(width: 48, height: 48)
                        .background(AppTheme.softFill(for: .orange))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.softBorder(for: .orange), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var debtAccountPickerPopover: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Main.selectDebtAccount)
                    .font(AppTheme.Typography.bodySemibold)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(mainVM.activeDebtAccounts) { account in
                    Button {
                        selectedDebtID = account.id ?? ""
                        showDebtAccountPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(AppTheme.Typography.bodySemibold)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(formatCurrency(account.currentBalance))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            if account.id == selectedAccount?.id {
                                Image(systemName: "checkmark")
                                    .font(AppTheme.Typography.compactRowIcon)
                                    .foregroundStyle(AppTheme.tint(for: .orange))
                            }
                        }
                        .appSurface(account.id == selectedAccount?.id ? .tinted(.orange) : .primary, padding: 14, cornerRadius: AppTheme.CornerRadius.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(AppTheme.background)
    }
}
