//
//  TransactionDetailView.swift
//  FinaLit
//

import SwiftUI

struct TransactionDetailView: View {
    let transactionID: String

    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var showDeleteAlert = false

    private var transaction: Transaction? {
        mainVM.transactions.first { $0.id == transactionID }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let transaction {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.softFill(for: transaction.category.tone))
                                    .frame(width: 64, height: 64)
                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(AppTheme.tint(for: transaction.category.tone))
                            }

                            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundStyle(transaction.isIncome ? AppTheme.success : AppTheme.textPrimary)
                                .monospacedDigit()
                                .padding(.horizontal, AppTheme.Spacing.screen)

                            Text(transaction.type == .income ? L10n.Main.income : L10n.Main.expense)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(spacing: 1) {
                            DetailRow(label: String(localized: "main.category"), value: String(localized: LocalizedStringResource(stringLiteral: "main.category\(transaction.category.rawValue)"))) 
                            DetailRow(label: String(localized: "main.date"), value: transaction.date.formatted(date: .long, time: .omitted))
                            if !transaction.note.isEmpty {
                                DetailRow(label: String(localized: "main.note"), value: transaction.note)
                            }
                            DetailRow(label: String(localized: "main.recurring"), value: transaction.isRecurring ? String(localized: "common.yes") : String(localized: "common.no"))
                        }
                        .appSurface(.primary, padding: 0, cornerRadius: AppTheme.CornerRadius.large)
                        .padding(.horizontal, AppTheme.Spacing.screen)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(L10n.Main.deleteTransaction)
                            }
                            .font(AppTheme.Typography.bodySemibold)
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.softFill(for: .danger))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        }
                        .padding(.horizontal, AppTheme.Spacing.screen)
                    }
                }
            } else {
                Text(L10n.Main.transactionNotFound)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .navigationTitle(L10n.Main.transaction)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Main.deleteTransaction2, isPresented: $showDeleteAlert) {
            Button(L10n.Main.delete, role: .destructive) {
                Task {
                    if let transaction {
                        await mainVM.deleteTransaction(transaction)
                        coordinator.pop()
                    }
                }
            }
            Button(L10n.Profile.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Main.thisCannotBeUndone)
        }
    }
}
