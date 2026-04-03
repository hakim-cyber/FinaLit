//
//  MonthlySnapshot.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct MonthlySnapshot: Codable, Identifiable {
    @DocumentID var id: String?
    var month: String
    var totalIncome: Double
    var totalExpenses: Double
    var netBalance: Double
    var savingsRate: Double
    var byCategory: [String: Double]
    var transactionCount: Int
    var computedAt: Date

    var isPositive: Bool { netBalance >= 0 }
}
