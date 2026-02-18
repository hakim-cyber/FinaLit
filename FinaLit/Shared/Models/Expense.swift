//
//  Expense.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// Expense.swift
// Shared/Models/

import Foundation

struct Expense: Codable, Identifiable {
    let id: String              // UUID string, Firestore document ID
    var amount: Double
    var category: SpendingCategory
    var note: String
    var date: Date
    
    // Convenience
    var month: String {         // "2026-02" — used to group by month
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

// Monthly summary — computed in ViewModel, not stored
struct MonthlyExpenseSummary {
    var month: String           // "2026-02"
    var totalSpent: Double
    var byCategory: [SpendingCategory: Double]
    
    // e.g. food is 38% of total
    func percentage(for category: SpendingCategory) -> Double {
        guard totalSpent > 0 else { return 0 }
        return ((byCategory[category] ?? 0) / totalSpent) * 100
    }
}