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
    case moneyManagement
    case general
}

enum ChatReplyMode: String {
    case social
    case concise
    case deepDive
}

struct ChatMessageAnalysis {
    let intent: ChatIntent
    let replyMode: ChatReplyMode
    let localReply: String?

    var requiresRemoteReply: Bool {
        localReply == nil
    }
}

struct AdvisorBudgetOverageSnapshot {
    let category: String
    let spent: Double
    let limit: Double

    var overAmount: Double {
        max(spent - limit, 0)
    }
}

struct AdvisorGoalSnapshot {
    let title: String
    let currentAmount: Double
    let targetAmount: Double
    let progressRatio: Double
    let deadlineText: String?
}

struct AdvisorContextSnapshot {
    let userName: String
    let age: Int
    let country: String
    let employmentStatus: String
    let selectedMonth: String
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
    let budgetOverages: [AdvisorBudgetOverageSnapshot]
    let keyInsights: [String]
    let activeGoals: [AdvisorGoalSnapshot]
    let debtSummary: String
    let purchaseAmount: Double?
    let purchaseToSavingsRatio: Double?
    let purchaseToIncomeRatio: Double?
    let affordabilityScore: Int?
}
