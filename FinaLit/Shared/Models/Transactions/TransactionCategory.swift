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

    var tone: AppTone {
        switch self {
        case .rent: return .orange
        case .food: return .amber
        case .transport: return .blue
        case .education: return .teal
        case .health: return .rose
        case .entertainment: return .accent
        case .shopping: return .rose
        case .other: return .slate
        case .salary: return .success
        case .freelance: return .info
        case .investment: return .accent
        case .gift: return .rose
        case .otherIncome: return .green
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
