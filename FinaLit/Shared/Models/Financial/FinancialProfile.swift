//
//  FinancialProfile.swift
//  FinaLit
//

import Foundation

struct FinancialProfile: Codable {
    var monthlyFixedExpenses: Double
    var monthlyVariableExpenses: Double
    var currentSavings: Double
    var hasDebt: Bool
    var debtAmount: Double?
    var emergencyFundMonths: Int
    var riskTolerance: RiskTolerance
    var shortTermGoal: String
    var longTermGoal: String
    var interestedInInvesting: Bool
    var knowledgeLevel: KnowledgeLevel

    var totalMonthlyExpenses: Double {
        monthlyFixedExpenses + monthlyVariableExpenses
    }

    var monthlySurplus: Double {
        0
    }
}
