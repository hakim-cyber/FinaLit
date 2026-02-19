//
//  Expense.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// Expense.swift
// Shared/Models/

import Foundation
import FirebaseFirestore

struct Expense: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID, not stored as a field
    var amount: Double
    var category: SpendingCategory
    var note: String
    var date: Date
    
    var month: String { Self.monthFormatter.string(from: date) }
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

extension Expense {
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

   
}
