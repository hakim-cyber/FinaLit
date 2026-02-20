//
//  Transaction.swift
//  FinaLit
//
//  Created by aplle on 2/20/26.
//


// TransactionModels.swift
// Shared/Models/

import Foundation
import FirebaseFirestore

// MARK: - Transaction
// Unified model for both income and expenses.
// Replaces the old Expense model entirely.

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var type:         TransactionType
    var amount:       Double
    var category:     TransactionCategory
    var date:         Date
    var note:         String
    var isRecurring:  Bool          = false
    var recurringID:  String?       = nil  // groups recurring transactions together

    // Convenience
    var month: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }

    var isExpense: Bool { type == .expense }
    var isIncome:  Bool { type == .income  }
}

// MARK: - Transaction Type
enum TransactionType: String, Codable, CaseIterable {
    case income  = "income"
    case expense = "expense"
}

// MARK: - Transaction Category
// Used for both expense categories and income types.
// Income types start with "income_" prefix for clarity.
enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    // ── Expense categories ─────────────────────────────────
    case rent          = "Rent"
    case food          = "Food"
    case transport     = "Transport"
    case education     = "Education"
    case health        = "Health"
    case entertainment = "Entertainment"
    case shopping      = "Shopping"
    case other         = "Other"

    // ── Income categories ──────────────────────────────────
    case salary        = "Salary"
    case freelance     = "Freelance"
    case investment    = "Investment Return"
    case gift          = "Gift"
    case otherIncome   = "Other Income"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rent:          return "house.fill"
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .education:     return "book.fill"
        case .health:        return "heart.fill"
        case .entertainment: return "tv.fill"
        case .shopping:      return "bag.fill"
        case .other:         return "ellipsis.circle.fill"
        case .salary:        return "banknote.fill"
        case .freelance:     return "laptopcomputer"
        case .investment:    return "arrow.up.right.circle.fill"
        case .gift:          return "gift.fill"
        case .otherIncome:   return "plus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .rent:          return "F87171"
        case .food:          return "FB923C"
        case .transport:     return "FACC15"
        case .education:     return "34D399"
        case .health:        return "F472B6"
        case .entertainment: return "818CF8"
        case .shopping:      return "A78BFA"
        case .other:         return "6B7280"
        case .salary:        return "10B981"
        case .freelance:     return "06B6D4"
        case .investment:    return "6366F1"
        case .gift:          return "EC4899"
        case .otherIncome:   return "84CC16"
        }
    }

    // Which type this category belongs to
    var transactionType: TransactionType {
        switch self {
        case .salary, .freelance, .investment, .gift, .otherIncome:
            return .income
        default:
            return .expense
        }
    }

    static var expenseCategories: [TransactionCategory] {
        allCases.filter { $0.transactionType == .expense }
    }

    static var incomeCategories: [TransactionCategory] {
        allCases.filter { $0.transactionType == .income }
    }
}

// MARK: - Recurring Template
// Stored once — generates transactions automatically or manually
struct RecurringTemplate: Codable, Identifiable {
    @DocumentID var id: String?
    var type:       TransactionType
    var amount:     Double
    var category:   TransactionCategory
    var note:       String
    var frequency:  RecurringFrequency
    var startDate:  Date
    var isActive:   Bool = true
}

enum RecurringFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly   = "Weekly"
    case monthly  = "Monthly"
    case yearly   = "Yearly"

    var id: String { rawValue }
}

// MARK: - Budget Limit
// User-defined spending cap per category per month
struct BudgetLimit: Codable, Identifiable {
    @DocumentID var id: String?
    var category: TransactionCategory
    var limit:    Double               // monthly limit in €
}

// MARK: - Financial Goal
// Structured goal with target amount and optional deadline
struct FinancialGoal: Codable, Identifiable {
    @DocumentID var id: String?
    var title:        String
    var targetAmount: Double
    var currentAmount: Double         // updated manually or from savings
    var deadline:     Date?
    var isCompleted:  Bool = false
    var createdAt:    Date

    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min((currentAmount / targetAmount) * 100, 100)
    }

    var isOnTrack: Bool {
        guard let deadline else { return true }
        let monthsLeft = Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 0
        guard monthsLeft > 0 else { return currentAmount >= targetAmount }
        let neededPerMonth = (targetAmount - currentAmount) / Double(monthsLeft)
        return neededPerMonth > 0
    }
}

// MARK: - Monthly Snapshot
// Computed and stored at end of each month or on demand.
// Powers month-over-month comparison and AI context.
struct MonthlySnapshot: Codable, Identifiable {
    @DocumentID var id: String?       // format: "2026-02"
    var month:            String      // "2026-02"
    var totalIncome:      Double
    var totalExpenses:    Double
    var netBalance:       Double      // income - expenses
    var savingsRate:      Double      // (net / income) * 100
    var byCategory:       [String: Double]  // category rawValue → amount
    var transactionCount: Int
    var computedAt:       Date

    // Convenience
    var isPositive: Bool { netBalance >= 0 }
}

// MARK: - Financial Summary (computed in ViewModel, never stored)
// Built fresh from transactions each time — the calculation engine output.
struct FinancialSummary {
    // Current month
    var monthlyIncome:      Double
    var monthlyExpenses:    Double
    var monthlyNet:         Double
    var savingsRate:        Double      // percentage
    var dailyAverage:       Double      // expenses / current day of month
    var byCategory:         [TransactionCategory: Double]

    // Overall
    var currentBalance:     Double      // total income - total expenses ever
    var totalSavings:       Double      // from financialProfile.currentSavings + net

    // Smart indicators
    var financialStability: FinancialStability
    var isOverspending:     Bool
    var discretionaryRatio: Double      // (entertainment + shopping) / income
    var expenseGrowthRate:  Double?     // vs last month, nil if no history

    // Category helpers
    func percentage(for category: TransactionCategory) -> Double {
        guard monthlyExpenses > 0 else { return 0 }
        return ((byCategory[category] ?? 0) / monthlyExpenses) * 100
    }

    func amount(for category: TransactionCategory) -> Double {
        byCategory[category] ?? 0
    }

    // Top 3 expense categories this month
    var topCategories: [(TransactionCategory, Double)] {
        byCategory
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Financial Stability
enum FinancialStability: String {
    case stable   = "Stable"     // savings > 3 months expenses
    case moderate = "Moderate"   // savings 1–3 months expenses
    case risky    = "Risky"      // savings < 1 month expenses

    var color: String {
        switch self {
        case .stable:   return "10B981"
        case .moderate: return "FACC15"
        case .risky:    return "F87171"
        }
    }

    var icon: String {
        switch self {
        case .stable:   return "shield.fill"
        case .moderate: return "shield.lefthalf.filled"
        case .risky:    return "exclamationmark.shield.fill"
        }
    }
}

// MARK: - Smart Insight
// Generated by MainViewModel from FinancialSummary — never stored
struct SmartInsight: Identifiable {
    let id    = UUID()
    var type:    InsightType
    var title:   String
    var message: String
    var icon:    String
    var color:   String
}

enum InsightType {
    case positive
    case warning
    case info
    case danger
}

// MARK: - AI Financial Context
// Passed to AI service when user asks a question
// Built by MainViewModel from all available data
struct AIFinancialContext {
    let monthlyIncome:       Double
    let monthlyExpenses:     Double
    let monthlyNet:          Double
    let savingsRate:         Double
    let currentBalance:      Double
    let totalSavings:        Double
    let topCategories:       [(TransactionCategory, Double)]
    let dailyAverage:        Double
    let stabilityLevel:      FinancialStability
    let isOverspending:      Bool
    let discretionaryRatio:  Double
    let shortTermGoal:       String
    let longTermGoal:        String
    let hasDebt:             Bool
    let debtAmount:          Double?
    let riskTolerance:       RiskTolerance
    let knowledgeLevel:      KnowledgeLevel

    var formattedPrompt: String {
        """
        FINANCIAL SNAPSHOT:
        Monthly Income:    \(monthlyIncome)€
        Monthly Expenses:  \(monthlyExpenses)€
        Monthly Net:       \(monthlyNet)€
        Savings Rate:      \(String(format: "%.1f", savingsRate))%
        Current Balance:   \(currentBalance)€
        Total Savings:     \(totalSavings)€
        Daily Avg Spend:   \(String(format: "%.0f", dailyAverage))€
        Stability:         \(stabilityLevel.rawValue)
        Overspending:      \(isOverspending ? "Yes ⚠️" : "No")
        Discretionary:     \(String(format: "%.1f", discretionaryRatio * 100))% of income

        TOP SPENDING CATEGORIES:
        \(topCategories.map { "- \($0.0.rawValue): \($0.1)€" }.joined(separator: "\n"))

        GOALS:
        Short-term: \(shortTermGoal)
        Long-term:  \(longTermGoal)

        DEBT: \(hasDebt ? "\(debtAmount ?? 0)€" : "None")
        RISK TOLERANCE: \(riskTolerance.rawValue)
        KNOWLEDGE LEVEL: \(knowledgeLevel.rawValue)
        """
    }
}