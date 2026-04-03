//
//  AIFinancialContext.swift
//  FinaLit
//

import Foundation

struct AIFinancialContext {
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

    var formattedPrompt: String {
        """
        FINANCIAL SNAPSHOT:
        Monthly Income:    \(formatCurrency(monthlyIncome))
        Monthly Expenses:  \(formatCurrency(monthlyExpenses))
        Monthly Net:       \(formatCurrency(monthlyNet))
        Savings Rate:      \(String(format: "%.1f", savingsRate))%
        Current Balance:   \(formatCurrency(currentBalance))
        Total Savings:     \(formatCurrency(totalSavings))
        Daily Avg Spend:   \(formatCurrency(dailyAverage))
        Stability:         \(stabilityLevel.rawValue)
        Overspending:      \(isOverspending ? "Yes ⚠️" : "No")
        Discretionary:     \(String(format: "%.1f", discretionaryRatio * 100))% of income

        TOP SPENDING CATEGORIES:
        \(topCategories.map { "- \($0.0.rawValue): \(formatCurrency($0.1))" }.joined(separator: "\n"))

        GOALS:
        Short-term: \(shortTermGoal)
        Long-term:  \(longTermGoal)

        DEBT: \(hasDebt ? formatCurrency(debtAmount ?? 0) : "None")
        RISK TOLERANCE: \(riskTolerance.rawValue)
        KNOWLEDGE LEVEL: \(knowledgeLevel.rawValue)
        """
    }
}
