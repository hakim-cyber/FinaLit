//
//  IncomeStability.swift
//  FinaLit
//

import Foundation

enum IncomeStability: String, Codable, CaseIterable, Identifiable {
    case stable = "Stable"
    case variable = "Variable"

    var id: String { rawValue }
}
