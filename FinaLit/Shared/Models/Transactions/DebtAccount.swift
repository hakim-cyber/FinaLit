//
//  DebtAccount.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct DebtAccount: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var currentBalance: Double
    var annualInterestRate: Double?
    var minimumMonthlyPayment: Double?
    var createdAt: Date
    var updatedAt: Date
    var isClosed: Bool = false
}
