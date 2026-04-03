//
//  TransactionsView.swift
//  FinaLit
//

import SwiftUI

struct TransactionsView: View {
    @Environment(MainViewModel.self) private var mainVM
    @Environment(Coordinator<MainPages>.self) private var coordinator
    @State private var filterType: TransactionType? = nil
    @State private var searchText: String = ""

    private struct TransactionDayGroup: Identifiable {
        let dayStart: Date
        let label: String
        let transactions: [Transaction]

        var id: Date { dayStart }
    }

    private var filtered: [Transaction] {
        mainVM.currentMonthTransactions.filter { transaction in
            let typeMatch = filterType == nil || transaction.type == filterType
            let searchMatch = searchText.isEmpty ||
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.rawValue.localizedCaseInsensitiveContains(searchText)
            return typeMatch && searchMatch
        }
    }

    private var grouped: [TransactionDayGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"

        let groupedByDay = Dictionary(grouping: filtered) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return groupedByDay
            .map { dayStart, transactions in
                TransactionDayGroup(
                    dayStart: dayStart,
                    label: formatter.string(from: dayStart),
                    transactions: transactions.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.dayStart > $1.dayStart }
    }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 0) {
                transactionsSummaryHeader
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                filterBar
                    .padding(.bottom, 12)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color(hex: "4B5563"))
                        .font(.system(size: 14))
                    TextField("Search transactions...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "6366F1"))
                }
                .padding(12)
                .background(Color(hex: "111118"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                if filtered.isEmpty {
                    Spacer()
                    Text(searchText.isEmpty ? "No transactions" : "No results")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "374151"))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(grouped) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(group.label.uppercased())
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color(hex: "4B5563"))
                                        .padding(.horizontal, 20)

                                    VStack(spacing: 1) {
                                        ForEach(group.transactions) { transaction in
                                            TransactionRow(transaction: transaction)
                                                .onTapGesture {
                                                    coordinator.push(.transactionDetail(transaction.id ?? ""))
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
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color(hex: "6B7280"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "0A0A0F"))
            .clipShape(Capsule())

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(formatCurrency(mainVM.currentMonthIncome.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("Income")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(Color(hex: "1F2937"))

                VStack(spacing: 2) {
                    Text(formatCurrency(mainVM.currentMonthExpenses.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "F87171"))
                    Text("Expenses")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "4B5563"))
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 28).background(Color(hex: "1F2937"))

                VStack(spacing: 2) {
                    Text("\(mainVM.currentMonthTransactions.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Total")
                        .font(.system(size: 10))
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
                FilterPill(label: "All", isActive: filterType == nil) { filterType = nil }
                FilterPill(label: "Expense", isActive: filterType == .expense) { filterType = .expense }
                FilterPill(label: "Income", isActive: filterType == .income) { filterType = .income }
            }
            .padding(.horizontal, 20)
        }
    }
}
