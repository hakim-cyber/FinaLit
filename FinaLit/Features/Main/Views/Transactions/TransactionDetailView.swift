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
            Color(hex: "0A0A0F").ignoresSafeArea()

            if let transaction {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: transaction.category.color).opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color(hex: transaction.category.color))
                            }

                            Text(formatSignedCurrency(amount: transaction.amount, isIncome: transaction.isIncome))
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(transaction.isIncome ? Color(hex: "10B981") : .white)

                            Text(transaction.type == .income ? "Income" : "Expense")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "4B5563"))
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
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Transaction")
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "F87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "F87171").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                    }
                }
            } else {
                Text("Transaction not found")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "4B5563"))
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
