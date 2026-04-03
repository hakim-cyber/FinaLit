//
//  FinancialSummary.swift
//  FinaLit
//

import Foundation

struct FinancialSummary {
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var monthlyNet: Double
    var savingsRate: Double
    var dailyAverage: Double
    var byCategory: [TransactionCategory: Double]
    var currentBalance: Double
    var totalSavings: Double
    var financialStability: FinancialStability
    var isOverspending: Bool
    var discretionaryRatio: Double
    var expenseGrowthRate: Double?

    func percentage(for category: TransactionCategory) -> Double {
        guard monthlyExpenses > 0 else { return 0 }
        return ((byCategory[category] ?? 0) / monthlyExpenses) * 100
    }

    func amount(for category: TransactionCategory) -> Double {
        byCategory[category] ?? 0
    }

    var topCategories: [(TransactionCategory, Double)] {
        byCategory
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }
}
