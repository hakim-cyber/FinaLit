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

    
    var localizedName: String {
        switch self {
        case .low: return String(localized: "profile.riskLow")
        case .medium: return String(localized: "profile.riskMedium")
        case .high: return String(localized: "profile.riskHigh")
        }
    }

    var description: String {
        switch self {
        case .low: return String(localized: "profile.riskLowDesc")
        case .medium: return String(localized: "profile.riskMediumDesc")
        case .high: return String(localized: "profile.riskHighDesc")
        }
    }
}
