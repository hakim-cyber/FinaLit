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
        You are FinaLit, a concise finance and money-management assistant.
        You provide educational guidance, not professional financial advice.

        Rules:
        - Respond in plain text only. No JSON, no markdown tables.
        - Be short and direct by default.
        - Answer the user's actual question first.
        - Use only the provided compact memory summary as prior context. Do not invent unseen chat history.
        - Use rational, conservative reasoning grounded in the provided user data.
        - Use the user's financial numbers only when they materially improve the answer.
        - For budgeting or money-management questions, focus on the most useful next step.
        - Explain trade-offs clearly when they matter.
        - Never guarantee returns and never recommend specific stocks or exact allocation percentages.
        - If key data is missing, state one brief assumption and ask at most one clarifying question.
        - Use everyday language.
        - Do not pad the answer with generic intros, repetitive disclaimers, or filler endings.
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

        RESPONSE MODE:
        \(replyMode.rawValue)

        CURRENT TASK:
        - Intent: \(intent.rawValue)
        - Mode rule: \(modeInstruction(for: replyMode))
        - Target length: \(targetLengthHint(for: replyMode))

        CONVERSATION MEMORY:
        \(compactMemoryBlock)

        FINANCIAL SNAPSHOT:
        Month: \(context.selectedMonth)
        Income: \(formatMoney(context.monthlyIncome))
        Expenses: \(formatMoney(context.monthlyExpenses))
        Monthly net: \(formatMoney(context.monthlyBalance))
        Savings: \(formatMoney(context.currentSavings))
        Savings rate: \(formatPercent(context.savingsRate))
        Expense ratio: \(formatPercent(context.expenseRatio))
        Daily average spending: \(formatMoney(context.dailyAverageSpending))
        Stability: \(context.stabilityLevel)
        Overspending: \(context.isOverspending ? "Yes" : "No")
        Discretionary ratio: \(formatPercent(context.discretionaryRatio))
        Top spending categories: \(topCategoriesLine)
        Budget overages: \(budgetOverageLine)
        Key insights: \(insightLine)
        Active goals: \(goalLine)
        Debt summary: \(context.debtSummary)

        USER PROFILE:
        Debt: \(formatMoney(context.debtAmount))
        Risk tolerance: \(context.riskTolerance)
        Knowledge level: \(context.knowledgeLevel)
        Emergency fund months: \(context.emergencyFundMonths)
        Weak spending areas: \(weaknesses)
        Goals: short=\(context.shortTermGoal) | long=\(context.longTermGoal)

        PURCHASE CHECK:
        \(purchaseLine)
        \(purchaseSavingsLine)
        \(purchaseIncomeLine)
        \(affordabilityLine)

        RESPONSE REQUIREMENTS:
        - Stay concise unless the mode says deepDive.
        - If the question is simple, answer in one compact paragraph.
        - Use bullets only if they make the answer clearer.
        - Use at most one or two concrete numbers when they help.
        - Give a practical next step when useful.
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

    private func modeInstruction(for mode: ChatReplyMode) -> String {
        switch mode {
        case .social:
            return "Reply with one short sentence, around 3-12 words."
        case .concise:
            return "Reply in 1-4 short sentences, around 30-90 words."
        case .deepDive:
            return "Start with a direct answer, then give a short step-by-step breakdown. Stay under 220 words."
        }
    }

    private func targetLengthHint(for mode: ChatReplyMode) -> String {
        switch mode {
        case .social:
            return "3-12 words"
        case .concise:
            return "30-90 words"
        case .deepDive:
            return "90-220 words"
        }
    }
}
