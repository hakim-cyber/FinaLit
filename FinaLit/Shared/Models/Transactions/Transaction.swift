//
//  Transaction.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var type: TransactionType
    var amount: Double
    var category: TransactionCategory
    var date: Date
    var note: String
    var isRecurring: Bool = false
    var recurringID: String? = nil

    var month: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    var isExpense: Bool { type == .expense }
    var isIncome: Bool { type == .income }
}
