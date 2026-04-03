//
//  TransactionType.swift
//  FinaLit
//

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
}
