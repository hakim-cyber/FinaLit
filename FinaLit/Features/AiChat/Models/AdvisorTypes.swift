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

struct AdvisorContextSnapshot {
    let userName: String
    let age: Int
    let country: String
    let employmentStatus: String
    let monthlyIncome: Double
    let monthlyExpenses: Double
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
    let dailyAverageSpending: Double
    let stabilityLevel: String
    let isOverspending: Bool
    let discretionaryRatio: Double
    let topSpendingCategories: [String]
    let purchaseAmount: Double?
    let purchaseToSavingsRatio: Double?
    let purchaseToIncomeRatio: Double?
    let affordabilityScore: Int?
}
