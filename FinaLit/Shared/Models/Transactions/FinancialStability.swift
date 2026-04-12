//
//  FinancialStability.swift
//  FinaLit
//

import Foundation
import SwiftUI

enum FinancialStability: String {
    case stable = "Stable"
    case moderate = "Moderate"
    case risky = "Risky"

    var localizedName: LocalizedStringKey {
        switch self {
        case .stable: return L10n.Main.stabilityStable
        case .moderate: return L10n.Main.stabilityModerate
        case .risky: return L10n.Main.stabilityRisky
        }
    }

    var tone: AppTone {
        switch self {
        case .stable: return .success
        case .moderate: return .warning
        case .risky: return .danger
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
