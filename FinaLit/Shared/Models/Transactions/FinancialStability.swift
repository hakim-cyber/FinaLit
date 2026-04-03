//
//  FinancialStability.swift
//  FinaLit
//

import Foundation

enum FinancialStability: String {
    case stable = "Stable"
    case moderate = "Moderate"
    case risky = "Risky"

    var color: String {
        switch self {
        case .stable: return "10B981"
        case .moderate: return "FACC15"
        case .risky: return "F87171"
        }
    }

    var icon: String {
        switch self {
        case .stable: return "shield.fill"
        case .moderate: return "shield.lefthalf.filled"
        case .risky: return "exclamationmark.shield.fill"
        }
    }
}
