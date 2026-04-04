//
//  ChatAdvisorContextBuilder.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct ChatAdvisorContextBuilder {
    func analyzeMessage(_ message: String) -> ChatMessageAnalysis {
        let normalized = normalizeMessage(message)

        if let localReply = localSocialReply(for: normalized) {
            return ChatMessageAnalysis(
                intent: .general,
                replyMode: .social,
                localReply: localReply
            )
        }

        return ChatMessageAnalysis(
            intent: classifyNormalizedIntent(for: normalized),
            replyMode: classifyReplyMode(for: normalized),
            localReply: nil
        )
    }

    func requiresRemoteReply(for message: String) -> Bool {
        analyzeMessage(message).requiresRemoteReply
    }

    func classifyIntent(for message: String) -> ChatIntent {
        classifyNormalizedIntent(for: normalizeMessage(message))
    }

    func buildSnapshot(
        user: User,
        message: String,
        intent: ChatIntent,
        assistantContext: AIAssistantContext?
    ) -> AdvisorContextSnapshot {
        let profile = user.profile
        let financial = user.financialProfile
        let behavior = user.behaviorProfile

        let monthlyIncome = assistantContext?.monthlyIncome ?? profile?.monthlyIncome ?? 0
        let monthlyExpenses = assistantContext?.monthlyExpenses ?? 0
        let monthlyBalance = assistantContext?.monthlyNet ?? (monthlyIncome - monthlyExpenses)
        let currentSavings = assistantContext?.totalSavings ?? financial?.currentSavings ?? 0
        let debtAmount = assistantContext?.debtAmount ?? financial?.debtAmount ?? 0

        let savingsRate = assistantContext.map { max($0.savingsRate, 0) / 100 } ??
            ratio(numerator: currentSavings, denominator: monthlyIncome)
        let expenseRatio = ratio(numerator: monthlyExpenses, denominator: monthlyIncome)
        let emergencyFundMonths = assistantContext.map {
            guard $0.monthlyExpenses > 0 else { return 0 }
            return max(Int(($0.totalSavings / $0.monthlyExpenses).rounded(.down)), 0)
        } ?? financial?.emergencyFundMonths ?? 0

        let purchaseAmount = intent == .purchaseDecision ? extractCandidateAmount(from: message) : nil
        let purchaseToSavingsRatio = purchaseAmount.map {
            ratio(numerator: $0, denominator: currentSavings)
        }
        let purchaseToIncomeRatio = purchaseAmount.map {
            ratio(numerator: $0, denominator: monthlyIncome)
        }

        return AdvisorContextSnapshot(
            userName: profile?.name ?? user.name,
            age: profile?.age ?? 0,
            country: profile?.country ?? AppRegion.defaultCountry,
            employmentStatus: profile?.employmentStatus.rawValue ?? "Unknown",
            selectedMonth: assistantContext?.selectedMonthDisplay ?? "Current month",
            monthlyIncome: monthlyIncome,
            monthlyExpenses: monthlyExpenses,
            monthlyBalance: monthlyBalance,
            currentSavings: currentSavings,
            debtAmount: debtAmount,
            emergencyFundMonths: emergencyFundMonths,
            riskTolerance: assistantContext?.riskTolerance.rawValue ?? financial?.riskTolerance.rawValue ?? "Unknown",
            knowledgeLevel: assistantContext?.knowledgeLevel.rawValue ?? financial?.knowledgeLevel.rawValue ?? "Unknown",
            shortTermGoal: assistantContext?.shortTermGoal ?? financial?.shortTermGoal ?? "Not set",
            longTermGoal: assistantContext?.longTermGoal ?? financial?.longTermGoal ?? "Not set",
            spendingWeaknesses: behavior?.spendingWeaknesses.map(\.rawValue) ?? [],
            savingsRate: savingsRate,
            expenseRatio: expenseRatio,
            dailyAverageSpending: assistantContext?.dailyAverage ?? 0,
            stabilityLevel: assistantContext?.stabilityLevel.rawValue ?? "Unknown",
            isOverspending: assistantContext?.isOverspending ?? (monthlyIncome > 0 && monthlyExpenses > monthlyIncome),
            discretionaryRatio: assistantContext?.discretionaryRatio ?? 0,
            topSpendingCategories: formatTopCategories(assistantContext?.topCategories ?? []),
            budgetOverages: formatBudgetOverages(assistantContext?.budgetOverages ?? []),
            keyInsights: assistantContext?.keyInsights ?? [],
            activeGoals: formatGoalSnapshots(assistantContext?.activeGoals ?? []),
            debtSummary: assistantContext?.debtSummary ?? defaultDebtSummary(for: debtAmount),
            purchaseAmount: purchaseAmount,
            purchaseToSavingsRatio: purchaseToSavingsRatio,
            purchaseToIncomeRatio: purchaseToIncomeRatio,
            affordabilityScore: affordabilityScore(
                purchaseAmount: purchaseAmount,
                savings: currentSavings,
                monthlyBalance: monthlyBalance
            )
        )
    }

    private func classifyNormalizedIntent(for normalized: String) -> ChatIntent {
        let purchaseKeywords = ["buy", "purchase", "afford", "cost", "price", "upgrade", "worth it"]
        if purchaseKeywords.contains(where: { normalized.contains($0) }) {
            return .purchaseDecision
        }

        let investmentKeywords = [
            "invest", "investment", "stock", "stocks", "etf", "etfs",
            "crypto", "bond", "portfolio", "index fund", "mutual fund"
        ]
        if investmentKeywords.contains(where: { normalized.contains($0) }) {
            return .investmentQuestion
        }

        let budgetKeywords = [
            "save", "saving", "savings", "budget", "spend less",
            "reduce expense", "reduce expenses", "reduce spending",
            "cut costs", "save money", "emergency fund"
        ]
        if budgetKeywords.contains(where: { normalized.contains($0) }) {
            return .budgetAdvice
        }

        let managementKeywords = [
            "overspend", "overspending", "spending", "expense", "expenses",
            "transaction", "transactions", "goal", "goals", "debt",
            "loan", "credit card", "pay off", "payoff", "cash flow",
            "cashflow", "category", "categories", "track", "manage money"
        ]
        if managementKeywords.contains(where: { normalized.contains($0) }) {
            return .moneyManagement
        }

        return .general
    }

    private func classifyReplyMode(for normalized: String) -> ChatReplyMode {
        let deepKeywords = [
            "explain", "in detail", "detailed", "step by step", "plan",
            "strategy", "compare", "pros and cons", "roadmap",
            "full breakdown", "analyze", "analysis", "walk me through"
        ]

        if deepKeywords.contains(where: { normalized.contains($0) }) {
            return .deepDive
        }

        return .concise
    }

    private func ratio(numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    private func formatTopCategories(_ categories: [(TransactionCategory, Double)]) -> [String] {
        categories.map {
            "\($0.0.rawValue): \(formatCurrency($0.1))"
        }
    }

    private func formatBudgetOverages(_ overages: [AssistantBudgetOverage]) -> [AdvisorBudgetOverageSnapshot] {
        overages.map {
            AdvisorBudgetOverageSnapshot(
                category: $0.category.rawValue,
                spent: $0.spent,
                limit: $0.limit
            )
        }
    }

    private func formatGoalSnapshots(_ goals: [AssistantGoalProgress]) -> [AdvisorGoalSnapshot] {
        goals.map {
            AdvisorGoalSnapshot(
                title: $0.title,
                currentAmount: $0.currentAmount,
                targetAmount: $0.targetAmount,
                progressRatio: $0.progressRatio,
                deadlineText: $0.deadlineText
            )
        }
    }

    private func defaultDebtSummary(for debtAmount: Double) -> String {
        guard debtAmount > 0 else { return "No active debt." }
        return "Debt total: \(formatCurrency(debtAmount))."
    }

    private func localSocialReply(for normalized: String) -> String? {
        guard !normalized.isEmpty, !containsFinanceKeywords(normalized) else { return nil }

        let greetingPhrases = [
            "hi", "hello", "hey", "hi there", "hey there",
            "good morning", "good afternoon", "good evening", "salam"
        ]
        if greetingPhrases.contains(normalized) {
            return "Hi, how can I help?"
        }

        let thanksPhrases = ["thanks", "thank you", "thx", "thanks a lot"]
        if thanksPhrases.contains(normalized) {
            return "You're welcome."
        }

        let byePhrases = ["bye", "goodbye", "see you", "see ya", "later", "talk later"]
        if byePhrases.contains(normalized) {
            return "See you soon."
        }

        return nil
    }

    private func containsFinanceKeywords(_ normalized: String) -> Bool {
        let financeKeywords = [
            "buy", "purchase", "afford", "cost", "price", "upgrade",
            "invest", "investment", "stock", "stocks", "etf", "crypto",
            "bond", "portfolio", "save", "saving", "savings", "budget",
            "overspend", "overspending", "spending", "expense", "expenses",
            "transaction", "transactions", "goal", "goals", "debt",
            "loan", "credit card", "pay off", "cash flow", "money"
        ]

        return financeKeywords.contains(where: { normalized.contains($0) })
    }

    private func normalizeMessage(_ message: String) -> String {
        let tokens = message
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)

        return tokens.joined(separator: " ")
    }

    private func affordabilityScore(
        purchaseAmount: Double?,
        savings: Double,
        monthlyBalance: Double
    ) -> Int? {
        guard let purchaseAmount else { return nil }

        if savings <= 0 {
            return 1
        }

        if purchaseAmount > savings {
            return monthlyBalance > 0 ? 3 : 1
        }

        let ratio = purchaseAmount / savings
        if ratio <= 0.2 { return 9 }
        if ratio <= 0.5 { return 6 }
        return 4
    }

    private func extractCandidateAmount(from text: String) -> Double? {
        let nsText = text as NSString
        let searchRange = NSRange(location: 0, length: nsText.length)

        let numberPattern = #"(?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?"#
        guard let numberRegex = try? NSRegularExpression(pattern: numberPattern) else { return nil }

        let candidates: [AmountCandidate] = numberRegex
            .matches(in: text, range: searchRange)
            .compactMap { match in
                guard match.range.location != NSNotFound else { return nil }
                let token = nsText.substring(with: match.range)
                guard let value = parseMonetaryInput(token), value > 0 else { return nil }
                return AmountCandidate(value: value, range: match.range)
            }

        guard !candidates.isEmpty else { return nil }

        let keywordPattern = #"\b(?:buy|purchase|afford|cost|price|spend|pay|upgrade|for)\b"#
        if let keywordRegex = try? NSRegularExpression(pattern: keywordPattern, options: [.caseInsensitive]) {
            let keywords = keywordRegex.matches(in: text, range: searchRange)
            if let best = bestContextualCandidate(from: candidates, keywordMatches: keywords) {
                return best.value
            }
        }

        if let currencyMatched = candidates.first(where: { hasCurrencyPrefix($0.range, in: nsText) }) {
            return currencyMatched.value
        }

        return candidates.first?.value
    }

    private func bestContextualCandidate(
        from candidates: [AmountCandidate],
        keywordMatches: [NSTextCheckingResult]
    ) -> AmountCandidate? {
        var best: (candidate: AmountCandidate, distance: Int)?

        for candidate in candidates {
            let distances = keywordMatches.compactMap { keyword -> Int? in
                let distance = candidate.range.location - NSMaxRange(keyword.range)
                return distance >= 0 ? distance : nil
            }

            guard let closestDistance = distances.min(), closestDistance <= 32 else { continue }

            if let currentBest = best {
                if closestDistance < currentBest.distance ||
                    (closestDistance == currentBest.distance &&
                     candidate.range.location < currentBest.candidate.range.location) {
                    best = (candidate, closestDistance)
                }
            } else {
                best = (candidate, closestDistance)
            }
        }

        return best?.candidate
    }

    private func hasCurrencyPrefix(_ amountRange: NSRange, in text: NSString) -> Bool {
        guard amountRange.location > 0 else { return false }
        let prefixStart = max(amountRange.location - 2, 0)
        let prefixLength = amountRange.location - prefixStart
        let prefix = text.substring(with: NSRange(location: prefixStart, length: prefixLength))
        return prefix.contains(where: { "$€£₼".contains($0) })
    }
}

private struct AmountCandidate {
    let value: Double
    let range: NSRange
}
