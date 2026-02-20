//
//  ChatAdvisorContextBuilder.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct ChatAdvisorContextBuilder {
    func classifyIntent(for message: String) -> ChatIntent {
        let normalized = message.lowercased()

        let purchaseKeywords = ["buy", "purchase", "afford", "cost", "price", "upgrade"]
        if purchaseKeywords.contains(where: { normalized.contains($0) }) {
            return .purchaseDecision
        }

        let investmentKeywords = ["invest", "stock", "etf", "crypto", "bond", "portfolio"]
        if investmentKeywords.contains(where: { normalized.contains($0) }) {
            return .investmentQuestion
        }

        let budgetKeywords = ["save", "budget", "spend less", "reduce expense", "cut costs"]
        if budgetKeywords.contains(where: { normalized.contains($0) }) {
            return .budgetAdvice
        }

        return .general
    }

    func buildSnapshot(
        user: User,
        message: String,
        intent: ChatIntent,
        financialContext: AIFinancialContext?
    ) -> AdvisorContextSnapshot {
        let profile = user.profile
        let financial = user.financialProfile
        let behavior = user.behaviorProfile

        let monthlyIncome = financialContext?.monthlyIncome ?? profile?.monthlyIncome ?? 0
        let monthlyExpenses = financialContext?.monthlyExpenses ?? 0
        let monthlyBalance = financialContext?.monthlyNet ?? (monthlyIncome - monthlyExpenses)
        let currentSavings = financialContext?.totalSavings ?? financial?.currentSavings ?? 0
        let debtAmount = financialContext?.debtAmount ?? financial?.debtAmount ?? 0

        let savingsRate = financialContext.map { max($0.savingsRate, 0) / 100 } ??
            ratio(numerator: currentSavings, denominator: monthlyIncome)
        let expenseRatio = ratio(numerator: monthlyExpenses, denominator: monthlyIncome)
        let emergencyFundMonths = financialContext.map {
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
            monthlyIncome: monthlyIncome,
            monthlyExpenses: monthlyExpenses,
            monthlyBalance: monthlyBalance,
            currentSavings: currentSavings,
            debtAmount: debtAmount,
            emergencyFundMonths: emergencyFundMonths,
            riskTolerance: financialContext?.riskTolerance.rawValue ?? financial?.riskTolerance.rawValue ?? "Unknown",
            knowledgeLevel: financialContext?.knowledgeLevel.rawValue ?? financial?.knowledgeLevel.rawValue ?? "Unknown",
            shortTermGoal: financialContext?.shortTermGoal ?? financial?.shortTermGoal ?? "Not set",
            longTermGoal: financialContext?.longTermGoal ?? financial?.longTermGoal ?? "Not set",
            spendingWeaknesses: behavior?.spendingWeaknesses.map(\.rawValue) ?? [],
            savingsRate: savingsRate,
            expenseRatio: expenseRatio,
            dailyAverageSpending: financialContext?.dailyAverage ?? 0,
            stabilityLevel: financialContext?.stabilityLevel.rawValue ?? "Unknown",
            isOverspending: financialContext?.isOverspending ?? (monthlyIncome > 0 && monthlyExpenses > monthlyIncome),
            discretionaryRatio: financialContext?.discretionaryRatio ?? 0,
            topSpendingCategories: formatTopCategories(financialContext?.topCategories ?? []),
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

    private func ratio(numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    private func formatTopCategories(_ categories: [(TransactionCategory, Double)]) -> [String] {
        categories.map {
            "\($0.0.rawValue): \(formatCurrency($0.1))"
        }
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
