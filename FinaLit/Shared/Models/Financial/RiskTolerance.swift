//
//  RiskTolerance.swift
//  FinaLit
//

import Foundation

enum RiskTolerance: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .low: return "I prefer safety over growth"
        case .medium: return "I'm okay with some risk for better returns"
        case .high: return "I chase high returns and accept losses"
        }
    }
}
