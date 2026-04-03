//
//  RecurringTemplate.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct RecurringTemplate: Codable, Identifiable {
    @DocumentID var id: String?
    var type: TransactionType
    var amount: Double
    var category: TransactionCategory
    var note: String
    var frequency: RecurringFrequency
    var startDate: Date
    var isActive: Bool = true
}
