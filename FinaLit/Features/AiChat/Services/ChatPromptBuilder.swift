//
//  ChatPromptBuilder.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct ChatPromptBuilder {
    func systemInstruction() -> String {
        """
        You are FinaLit, a financial literacy assistant.
        You provide educational guidance, not professional financial advice.

        Rules:
        - Respond in plain text only. No JSON, no markdown tables.
        - Use rational, conservative reasoning grounded in the provided user data.
        - Adapt to the user's intent: purchase decision, investing question, budgeting, or general financial question.
        - Explain trade-offs and consequences clearly.
        - Never guarantee returns and never recommend specific stocks or exact allocation percentages.
        - If data is missing, state assumptions and ask one clarifying question.
        - Keep answers practical and concise.
        - End every response with: "Educational guidance, not financial advice."
        """
    }

    func userPrompt(
        userMessage: String,
        intent: ChatIntent,
        context: AdvisorContextSnapshot
    ) -> String {
        let weaknesses = context.spendingWeaknesses.isEmpty
            ? "None provided"
            : context.spendingWeaknesses.joined(separator: ", ")

        let purchaseLine: String
        if let purchase = context.purchaseAmount {
            purchaseLine = "Purchase Amount Candidate: \(formatCurrency(purchase))"
        } else {
            purchaseLine = "Purchase Amount Candidate: N/A"
        }

        let affordabilityLine: String
        if let affordabilityScore = context.affordabilityScore {
            affordabilityLine = "Affordability Score (local): \(affordabilityScore)/10"
        } else {
            affordabilityLine = "Affordability Score (local): N/A"
        }

        let purchaseSavingsLine: String
        if let ratio = context.purchaseToSavingsRatio {
            purchaseSavingsLine = "Purchase/Savings Ratio: \(formatPercent(ratio))"
        } else {
            purchaseSavingsLine = "Purchase/Savings Ratio: N/A"
        }

        let purchaseIncomeLine: String
        if let ratio = context.purchaseToIncomeRatio {
            purchaseIncomeLine = "Purchase/Income Ratio: \(formatPercent(ratio))"
        } else {
            purchaseIncomeLine = "Purchase/Income Ratio: N/A"
        }

        return """
        USER QUESTION:
        \(userMessage)

        CLASSIFIED INTENT:
        \(intent.rawValue)

        USER CONTEXT:
        Name: \(context.userName)
        Age: \(context.age)
        Country: \(context.country)
        Employment: \(context.employmentStatus)
        Monthly Income: \(formatCurrency(context.monthlyIncome))
        Fixed Expenses: \(formatCurrency(context.fixedExpenses))
        Variable Expenses: \(formatCurrency(context.variableExpenses))
        Total Expenses: \(formatCurrency(context.totalExpenses))
        Monthly Balance: \(formatCurrency(context.monthlyBalance))
        Current Savings: \(formatCurrency(context.currentSavings))
        Debt: \(formatCurrency(context.debtAmount))
        Emergency Fund (months): \(context.emergencyFundMonths)
        Risk Tolerance: \(context.riskTolerance)
        Knowledge Level: \(context.knowledgeLevel)
        Savings Rate: \(formatPercent(context.savingsRate))
        Expense Ratio: \(formatPercent(context.expenseRatio))
        Spending Weaknesses: \(weaknesses)
        Short-Term Goal: \(context.shortTermGoal)
        Long-Term Goal: \(context.longTermGoal)
        \(purchaseLine)
        \(purchaseSavingsLine)
        \(purchaseIncomeLine)
        \(affordabilityLine)

        Write a practical answer that includes:
        1) Quick decision summary
        2) Why this makes sense based on the numbers
        3) Recommended next step
        4) A safer alternative if relevant
        """
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}
