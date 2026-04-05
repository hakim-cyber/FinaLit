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
        You are FinaLit, a helpful finance assistant.
        Give educational guidance only, not professional financial advice.
        Use only the user's question, the memory summary, and the financial snapshot provided in the prompt.
        Answer the user's question directly in plain text.
        If the user asks for one of their numbers, give the exact number from the snapshot first.
        If data is missing, unavailable, or zero, say that clearly and do not guess.
        Use simple everyday language.
        Use bullets only when they make the answer clearer.
        Do not add filler or repeat the same disclaimer in every reply.
        """
    }

    func userPrompt(
        userMessage: String,
        intent: ChatIntent,
        replyMode: ChatReplyMode,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
    ) -> String {
        let weaknesses = context.spendingWeaknesses.isEmpty
            ? "None provided"
            : context.spendingWeaknesses.joined(separator: ", ")

        let purchaseLine: String
        if let purchase = context.purchaseAmount {
            purchaseLine = "Purchase Amount Candidate: \(formatMoney(purchase))"
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

        let topCategoriesLine = context.topSpendingCategories.isEmpty
            ? "None yet"
            : context.topSpendingCategories.joined(separator: " | ")

        let budgetOverageLine = formatBudgetOverages(context.budgetOverages)
        let insightLine = context.keyInsights.isEmpty
            ? "None"
            : context.keyInsights.joined(separator: " | ")
        let goalLine = formatGoals(context.activeGoals)

        let compactMemoryBlock: String
        if let conversationMemory, !conversationMemory.isEmpty {
            compactMemoryBlock = conversationMemory
        } else {
            compactMemoryBlock = "none"
        }

        return """
        USER QUESTION:
        \(userMessage)

        REQUEST TYPE:
        Intent: \(intent.rawValue)
        Response style: \(responseStyle(for: replyMode))

        MEMORY SUMMARY:
        \(compactMemoryBlock)

        FINANCIAL SNAPSHOT:
        Month: \(context.selectedMonth)
        Income: \(formatMoney(context.monthlyIncome))
        Expenses: \(formatMoney(context.monthlyExpenses))
        Monthly net: \(formatMoney(context.monthlyBalance))
        Savings: \(formatMoney(context.currentSavings))
        Debt: \(formatMoney(context.debtAmount))
        Debt summary: \(context.debtSummary)
        Savings rate: \(formatPercent(context.savingsRate))
        Expense ratio: \(formatPercent(context.expenseRatio))
        Daily average spending: \(formatMoney(context.dailyAverageSpending))
        Emergency fund months: \(context.emergencyFundMonths)
        Stability: \(context.stabilityLevel)
        Overspending: \(context.isOverspending ? "Yes" : "No")
        Discretionary ratio: \(formatPercent(context.discretionaryRatio))
        Top spending categories: \(topCategoriesLine)
        Budget overages: \(budgetOverageLine)
        Key insights: \(insightLine)
        Active goals: \(goalLine)

        USER PROFILE:
        Risk tolerance: \(context.riskTolerance)
        Knowledge level: \(context.knowledgeLevel)
        Weak spending areas: \(weaknesses)
        Goals: short=\(context.shortTermGoal) | long=\(context.longTermGoal)

        PURCHASE CHECK:
        \(purchaseLine)
        \(purchaseSavingsLine)
        \(purchaseIncomeLine)
        \(affordabilityLine)

        FINAL INSTRUCTION:
        Answer naturally. If the answer is directly in the snapshot, say it clearly in the first sentence.
        """
    }

    private func formatMoney(_ value: Double) -> String {
        formatCurrency(value)
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    private func formatBudgetOverages(_ overages: [AdvisorBudgetOverageSnapshot]) -> String {
        guard !overages.isEmpty else { return "None" }

        return overages
            .map {
                "\($0.category) over by \(formatMoney($0.overAmount)) (spent \(formatMoney($0.spent)) on \(formatMoney($0.limit)) budget)"
            }
            .joined(separator: " | ")
    }

    private func formatGoals(_ goals: [AdvisorGoalSnapshot]) -> String {
        guard !goals.isEmpty else { return "None" }

        return goals
            .map { goal in
                let progress = String(format: "%.0f%%", goal.progressRatio * 100)
                let deadline = goal.deadlineText.map { ", deadline \($0)" } ?? ""
                return "\(goal.title): \(progress) (\(formatMoney(goal.currentAmount))/\(formatMoney(goal.targetAmount))\(deadline)"
            }
            .joined(separator: " | ")
    }

    private func responseStyle(for mode: ChatReplyMode) -> String {
        switch mode {
        case .social:
            return "friendly"
        case .concise:
            return "direct"
        case .deepDive:
            return "detailed"
        }
    }
}
