//
//  AdvisorTypes.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation

enum ChatIntent: String {
    case purchaseDecision
    case investmentQuestion
    case budgetAdvice
    case general
}

struct ChatTurn {
    let role: ChatRole
    let text: String
}

struct AdvisorContextSnapshot {
    let userName: String
    let age: Int
    let country: String
    let employmentStatus: String
    let monthlyIncome: Double
    let fixedExpenses: Double
    let variableExpenses: Double
    let totalExpenses: Double
    let monthlyBalance: Double
    let currentSavings: Double
    let debtAmount: Double
    let emergencyFundMonths: Int
    let riskTolerance: String
    let knowledgeLevel: String
    let shortTermGoal: String
    let longTermGoal: String
    let spendingWeaknesses: [String]
    let savingsRate: Double
    let expenseRatio: Double
    let purchaseAmount: Double?
    let purchaseToSavingsRatio: Double?
    let purchaseToIncomeRatio: Double?
    let affordabilityScore: Int?
}
