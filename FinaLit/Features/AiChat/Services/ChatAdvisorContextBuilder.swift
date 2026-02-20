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
            country: profile?.country ?? "Unknown",
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
            "\($0.0.rawValue): \(String(format: "%.0f", $0.1))€"
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
        let pattern = #"(\d+(?:[.,]\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)

        let numbers: [Double] = matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let numberRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            let normalized = text[numberRange].replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        }

        return numbers.max()
    }
}
