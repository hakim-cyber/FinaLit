//
//  FinancialProfile.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// FinancialProfile.swift
// Shared/Models/
// Filled during Onboarding Step 2 — Financial Status + Step 3 — Risk & Goals

import Foundation

struct FinancialProfile: Codable {
    
    // MARK: - Step 2: Financial Status
    var monthlyFixedExpenses: Double
    var monthlyVariableExpenses: Double
    var currentSavings: Double
    var hasDebt: Bool
    var debtAmount: Double?          // nil if hasDebt == false
    var emergencyFundMonths: Int     // 0 = none, 1,2,3,6,12+
    
    // MARK: - Step 3: Risk & Goals
    var riskTolerance: RiskTolerance
    var shortTermGoal: String        // free text, e.g. "Save 5000₼ in 1 year"
    var longTermGoal: String         // free text, e.g. "Buy a house"
    var interestedInInvesting: Bool
    var knowledgeLevel: KnowledgeLevel
    
    // MARK: - Computed helpers (used for AI prompt + insights)
    var totalMonthlyExpenses: Double {
        monthlyFixedExpenses + monthlyVariableExpenses
    }
    
    // How much is left after expenses
    var monthlySurplus: Double {
        // Requires income from UserProfile — calculated in ViewModel, not here
        0 // placeholder, computed in FinancialViewModel
    }
}

enum RiskTolerance: String, Codable, CaseIterable, Identifiable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low:    return "I prefer safety over growth"
        case .medium: return "I'm okay with some risk for better returns"
        case .high:   return "I chase high returns and accept losses"
        }
    }
}

enum KnowledgeLevel: String, Codable, CaseIterable, Identifiable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
    
    var id: String { rawValue }
}
