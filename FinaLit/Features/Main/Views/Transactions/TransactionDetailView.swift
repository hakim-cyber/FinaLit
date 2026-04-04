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

                            Text(transaction.type == .income ? "Income" : "Expense")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(spacing: 1) {
                            DetailRow(label: "Category", value: transaction.category.rawValue)
                            DetailRow(label: "Date", value: transaction.date.formatted(date: .long, time: .omitted))
                            if !transaction.note.isEmpty {
                                DetailRow(label: "Note", value: transaction.note)
                            }
                            DetailRow(label: "Recurring", value: transaction.isRecurring ? "Yes" : "No")
                        }
                        .appSurface(.primary, padding: 0, cornerRadius: AppTheme.CornerRadius.large)
                        .padding(.horizontal, AppTheme.Spacing.screen)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Transaction")
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
                Text("Transaction not found")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Transaction?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if let transaction {
                        await mainVM.deleteTransaction(transaction)
                        coordinator.pop()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}
