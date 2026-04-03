//
//  BudgetLimit.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct BudgetLimit: Codable, Identifiable {
    @DocumentID var id: String?
    var category: TransactionCategory
    var limit: Double
}
