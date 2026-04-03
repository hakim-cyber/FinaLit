//
//  TransactionCategory.swift
//  FinaLit
//

import Foundation

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case rent = "Rent"
    case food = "Food"
    case transport = "Transport"
    case education = "Education"
    case health = "Health"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case other = "Other"
    case salary = "Salary"
    case freelance = "Freelance"
    case investment = "Investment Return"
    case gift = "Gift"
    case otherIncome = "Other Income"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rent: return "house.fill"
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "arrow.up.right.circle.fill"
        case .gift: return "gift.fill"
        case .otherIncome: return "plus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .rent: return "F87171"
        case .food: return "FB923C"
        case .transport: return "FACC15"
        case .education: return "34D399"
        case .health: return "F472B6"
        case .entertainment: return "818CF8"
        case .shopping: return "A78BFA"
        case .other: return "6B7280"
        case .salary: return "10B981"
        case .freelance: return "06B6D4"
        case .investment: return "6366F1"
        case .gift: return "EC4899"
        case .otherIncome: return "84CC16"
        }
    }

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
