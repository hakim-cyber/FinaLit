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
        - Use only the provided compact memory summary as prior context. Do not invent unseen chat history.
        - Adapt to the user's intent: purchase decision, investing question, budgeting, or general financial question.
        - Explain trade-offs and consequences clearly.
        - Never guarantee returns and never recommend specific stocks or exact allocation percentages.
        - If data is missing, state assumptions and ask one clarifying question.
        - Keep answers practical and useful.
        - Use normal everyday language, like a thoughtful friend.
        - Adapt answer depth to user intent and complexity.
        - For simple questions: concise answer.
        - For planning, comparisons, or explicit "explain in detail": provide a deeper step-by-step answer.
        - Prefer short sections over long paragraphs.
        - Use correct grammar and spacing.
        - Do not use the exact same ending line in every response.
        """
    }

    func userPrompt(
        userMessage: String,
        intent: ChatIntent,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
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

        let compactMemoryBlock: String
        if let conversationMemory, !conversationMemory.isEmpty {
            compactMemoryBlock = """
            CONVERSATION MEMORY (compact, local summary only):
            \(conversationMemory)
            """
        } else {
            compactMemoryBlock = "CONVERSATION MEMORY: none"
        }

        let styleHint = responseStyleHint(for: userMessage, intent: intent)
        let detailMode = responseDetailMode(for: userMessage)
        let targetLength = targetLengthHint(for: detailMode)

        return """
        USER QUESTION:
        \(userMessage)

        CLASSIFIED INTENT:
        \(intent.rawValue)

        CONTEXT POLICY:
        This analysis uses:
        - current question
        - compact conversation memory summary (not full history)
        - user profile data below

        \(compactMemoryBlock)

        USER DATA (compact):
        Income: \(formatCurrency(context.monthlyIncome))
        Expenses (fixed/variable/total): \(formatCurrency(context.fixedExpenses)) / \(formatCurrency(context.variableExpenses)) / \(formatCurrency(context.totalExpenses))
        Monthly balance: \(formatCurrency(context.monthlyBalance))
        Savings: \(formatCurrency(context.currentSavings))
        Debt: \(formatCurrency(context.debtAmount))
        Risk tolerance: \(context.riskTolerance)
        Knowledge level: \(context.knowledgeLevel)
        Savings rate: \(formatPercent(context.savingsRate))
        Expense ratio: \(formatPercent(context.expenseRatio))
        Weak spending areas: \(weaknesses)
        Goals: short=\(context.shortTermGoal) | long=\(context.longTermGoal)
        \(purchaseLine)
        \(purchaseSavingsLine)
        \(purchaseIncomeLine)
        \(affordabilityLine)

        RESPONSE STYLE:
        - Talk like a helpful friend who understands personal finance.
        - Do not force the same template every time.
        - Vary format naturally (short paragraph, or small bullets if clearer).
        - Mention at least one concrete number from the user data.
        - Keep response useful and focused.
        - Style variation for this reply: \(styleHint)
        - Detail mode for this reply: \(detailMode.rawValue)
        - Target length: \(targetLength)
        """
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    private func responseStyleHint(for userMessage: String, intent: ChatIntent) -> String {
        let normalized = "\(intent.rawValue)|\(userMessage.lowercased())"
        let hash = normalized.hashValue.magnitude

        switch hash % 3 {
        case 0:
            return "Warm and direct: one clear recommendation, then one short reason."
        case 1:
            return "Coaching tone: short explanation, then one practical next step."
        default:
            return "Conversational: balanced pros/cons, then a gentle suggestion."
        }
    }

    private func responseDetailMode(for userMessage: String) -> ResponseDetailMode {
        let message = userMessage.lowercased()

        let conciseKeywords = [
            "quick",
            "short",
            "brief",
            "tldr",
            "one line",
            "summary only"
        ]

        if conciseKeywords.contains(where: { message.contains($0) }) {
            return .concise
        }

        let deepKeywords = [
            "explain",
            "in detail",
            "detailed",
            "step by step",
            "plan",
            "strategy",
            "compare",
            "pros and cons",
            "roadmap",
            "full breakdown",
            "analyze",
            "analysis"
        ]

        if deepKeywords.contains(where: { message.contains($0) }) || message.split(separator: " ").count >= 22 {
            return .deep
        }

        return .standard
    }

    private func targetLengthHint(for mode: ResponseDetailMode) -> String {
        switch mode {
        case .concise:
            return "60-110 words"
        case .standard:
            return "100-180 words"
        case .deep:
            return "180-320 words"
        }
    }
}

private enum ResponseDetailMode: String {
    case concise
    case standard
    case deep
}
