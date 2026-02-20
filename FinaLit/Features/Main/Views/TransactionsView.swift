//
//  TransactionsView.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// TransactionsView.swift
// Features/Main/Views/

import SwiftUI

struct TransactionsView: View {
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var filterType: TransactionType? = nil
    @State private var searchText: String = ""

    private var filtered: [Transaction] {
        mainVM.currentMonthTransactions.filter { tx in
            let typeMatch     = filterType == nil || tx.type == filterType
            let searchMatch   = searchText.isEmpty ||
                tx.note.localizedCaseInsensitiveContains(searchText) ||
                tx.category.rawValue.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }

    // Group by day
    private var grouped: [(String, [Transaction])] {
        let calendar  = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"

        var dict: [String: [Transaction]] = [:]
        for tx in filtered {
            let key = formatter.string(from: tx.date)
            dict[key, default: []].append(tx)
        }
        return dict.sorted { lhs, rhs in
            // Sort groups by date descending
            let df = DateFormatter()
            df.dateFormat = "EEEE, d MMM"
            let d1 = df.date(from: lhs.key) ?? Date.distantPast
            let d2 = df.date(from: rhs.key) ?? Date.distantPast
            return d1 > d2
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Month + summary header ─────────────────────────────────
                transactionsSummaryHeader
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // ── Filter bar ─────────────────────────────────────────────
                filterBar
                    .padding(.bottom, 12)

                // ── Search ─────────────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color(hex: "4B5563"))
                        .font(.system(size: 14))
                    TextField("Search transactions...", text: $searchText)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "6366F1"))
                }
                .padding(12)
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // ── Grouped list ───────────────────────────────────────────
                if filtered.isEmpty {
                    Spacer()
                    Text(searchText.isEmpty ? "No transactions" : "No results")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Color(hex: "374151"))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(grouped, id: \.0) { day, txs in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(day.uppercased())
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "4B5563"))
                                        .padding(.horizontal, 20)

                                    VStack(spacing: 1) {
                                        ForEach(txs) { tx in
                                            TransactionRow(transaction: tx)
                                                .onTapGesture {
                                                    coordinator.push(.transactionDetail(tx.id ?? ""))
                                                }
                                        }
                                    }
                                    .background(Color(hex: "111118"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .padding(.horizontal, 20)
                                }
                            }
                            Spacer(minLength: 40)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var transactionsSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                Text(mainVM.selectedMonthDisplay.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(Color(hex: "6B7280"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "0A0A0F"))
            .clipShape(Capsule())

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(formatCurrency(mainVM.currentMonthIncome.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("Income")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(Color(hex: "1F2937"))

                VStack(spacing: 2) {
                    Text(formatCurrency(mainVM.currentMonthExpenses.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "F87171"))
                    Text("Expenses")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(Color(hex: "1F2937"))

                VStack(spacing: 2) {
                    Text("\(mainVM.currentMonthTransactions.count)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("Total")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color(hex: "111118"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "All",     isActive: filterType == nil)     { filterType = nil }
                FilterPill(label: "Expense", isActive: filterType == .expense) { filterType = .expense }
                FilterPill(label: "Income",  isActive: filterType == .income)  { filterType = .income }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct FilterPill: View {
    let label:    String
    let isActive: Bool
    let onTap:    () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isActive ? .white : Color(hex: "4B5563"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color(hex: "6366F1") : Color(hex: "111118"))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isActive ? Color.clear : Color(hex: "1F2937"),
                        lineWidth: 1
                    )
                )
        }
    }
}

// MARK: - Transaction Detail View
struct TransactionDetailView: View {
    let transactionID: String
    @Environment(MainViewModel.self)          private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var showDeleteAlert = false

    private var transaction: Transaction? {
        mainVM.transactions.first { $0.id == transactionID }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            if let tx = transaction {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Amount hero ────────────────────────────────────
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: tx.category.color).opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: tx.category.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color(hex: tx.category.color))
                            }

                            Text(formatSignedCurrency(amount: tx.amount, isIncome: tx.isIncome))
                                .font(.system(size: 40, weight: .light, design: .serif))
                                .foregroundStyle(tx.isIncome ? Color(hex: "10B981") : .white)

                            Text(tx.type == .income ? "Income" : "Expense")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color(hex: "4B5563"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        // ── Details ────────────────────────────────────────
                        VStack(spacing: 1) {
                            DetailRow(label: "Category", value: tx.category.rawValue)
                            DetailRow(label: "Date",     value: tx.date.formatted(date: .long, time: .omitted))
                            if !tx.note.isEmpty {
                                DetailRow(label: "Note", value: tx.note)
                            }
                            DetailRow(label: "Recurring", value: tx.isRecurring ? "Yes" : "No")
                        }
                        .background(Color(hex: "111118"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)

                        // ── Delete button ──────────────────────────────────
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Transaction")
                            }
                            .font(.system(size: 15, design: .monospaced))
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
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Color(hex: "4B5563"))
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Transaction?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    if let tx = transaction {
                        await mainVM.deleteTransaction(tx)
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

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color(hex: "4B5563"))
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
