//
//  BudgetView.swift
//  FinaLit
//

import SwiftUI

struct BudgetView: View {
    @Environment(MainViewModel.self) private var mainVM
    @State private var editingLimits: [TransactionCategory: String] = [:]
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(mainVM.selectedMonthDisplay.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "6B7280"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "111118"))
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    HStack {
                        Text("Set monthly limits per category.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "4B5563"))
                        Spacer()
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveLimits()
                            } else {
                                startEditing()
                            }
                            isEditing.toggle()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6366F1"))
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        ForEach(TransactionCategory.expenseCategories) { category in
                            BudgetCategoryCard(
                                category: category,
                                spent: mainVM.summary?.amount(for: category) ?? 0,
                                limit: mainVM.budgetLimit(for: category),
                                isEditing: isEditing,
                                editingText: Binding(
                                    get: { editingLimits[category] ?? "" },
                                    set: { editingLimits[category] = $0 }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    if let summary = mainVM.summary {
                        TotalBudgetCard(
                            spent: summary.monthlyExpenses,
                            totalLimit: mainVM.budgetLimits.reduce(0) { $0 + $1.limit }
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startEditing() {
        for category in TransactionCategory.expenseCategories {
            if let limit = mainVM.budgetLimit(for: category) {
                editingLimits[category] = String(format: "%.0f", limit)
            } else {
                editingLimits[category] = ""
            }
        }
    }

    private func saveLimits() {
        var limits: [BudgetLimit] = []
        for (category, text) in editingLimits {
            if let value = parseMonetaryInput(text), value > 0 {
                limits.append(
                    BudgetLimit(
                        id: UUID().uuidString,
                        category: category,
                        limit: value
                    )
                )
            }
        }
        Task { await mainVM.saveBudgetLimits(limits) }
    }
}
