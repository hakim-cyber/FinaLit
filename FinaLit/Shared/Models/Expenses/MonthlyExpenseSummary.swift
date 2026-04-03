//
//  MonthlyExpenseSummary.swift
//  FinaLit
//

import Foundation

struct MonthlyExpenseSummary {
    var month: String
    var totalSpent: Double
    var byCategory: [SpendingCategory: Double]

    func percentage(for category: SpendingCategory) -> Double {
        guard totalSpent > 0 else { return 0 }
        return ((byCategory[category] ?? 0) / totalSpent) * 100
    }
}
