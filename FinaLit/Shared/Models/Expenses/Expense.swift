//
//  Expense.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Expense: Codable, Identifiable {
    @DocumentID var id: String?
    var amount: Double
    var category: SpendingCategory
    var note: String
    var date: Date

    var month: String { Self.monthFormatter.string(from: date) }
}

extension Expense {
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}
