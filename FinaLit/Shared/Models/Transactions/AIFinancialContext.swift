//
//  AIFinancialContext.swift
//  FinaLit
//

import Foundation

struct AssistantBudgetOverage: Hashable {
    let category: TransactionCategory
    let spent: Double
    let limit: Double

    var overAmount: Double {
        max(spent - limit, 0)
    }
}

struct AssistantGoalProgress: Hashable {
    let title: String
    let currentAmount: Double
    let targetAmount: Double
    let progressRatio: Double
    let deadlineText: String?
}

struct AIAssistantContext {
    let selectedMonth: String
    let selectedMonthDisplay: String
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let monthlyNet: Double
    let savingsRate: Double
    let currentBalance: Double
    let totalSavings: Double
    let topCategories: [(TransactionCategory, Double)]
    let dailyAverage: Double
    let stabilityLevel: FinancialStability
    let isOverspending: Bool
    let discretionaryRatio: Double
    let shortTermGoal: String
    let longTermGoal: String
    let hasDebt: Bool
    let debtAmount: Double?
    let riskTolerance: RiskTolerance
    let knowledgeLevel: KnowledgeLevel
    let budgetOverages: [AssistantBudgetOverage]
    let keyInsights: [String]
    let activeGoals: [AssistantGoalProgress]
    let debtSummary: String

    var changeToken: String {
        let categoriesToken = topCategories
            .map { "\($0.0.rawValue):\($0.1)" }
            .joined(separator: "|")
        let budgetsToken = budgetOverages
            .map { "\($0.category.rawValue):\($0.spent):\($0.limit)" }
            .joined(separator: "|")
        let goalsToken = activeGoals
            .map { "\($0.title):\($0.progressRatio):\($0.deadlineText ?? "-")" }
            .joined(separator: "|")
        let insightsToken = keyInsights.joined(separator: "|")

        return [
            selectedMonth,
            selectedMonthDisplay,
            String(monthlyIncome),
            String(monthlyExpenses),
            String(monthlyNet),
            String(totalSavings),
            String(isOverspending),
            String(debtAmount ?? 0),
            categoriesToken,
            budgetsToken,
            goalsToken,
            insightsToken,
            debtSummary
        ].joined(separator: "||")
    }
}
