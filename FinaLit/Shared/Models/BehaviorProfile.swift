//
//  BehaviorProfile.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// BehaviorProfile.swift
// Shared/Models/
// Filled during Onboarding Step 4 — Lifestyle & Behavior

import Foundation

struct BehaviorProfile: Codable {
    var topHobbies: [String]                  // max 3, free text or from picker
    var spendingWeaknesses: [SpendingCategory] // multi-select, max 3
}

// Shared across BehaviorProfile + Expense
enum SpendingCategory: String, Codable, CaseIterable, Identifiable {
    case food          = "Food"
    case transport     = "Transport"
    case rent          = "Rent"
    case entertainment = "Entertainment"
    case education     = "Education"
    case health        = "Health"
    case tech          = "Tech"
    case clothes       = "Clothes"
    case travel        = "Travel"
    case other         = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .rent:          return "house.fill"
        case .entertainment: return "tv.fill"
        case .education:     return "book.fill"
        case .health:        return "heart.fill"
        case .tech:          return "laptopcomputer"
        case .clothes:       return "tshirt.fill"
        case .travel:        return "airplane"
        case .other:         return "ellipsis.circle.fill"
        }
    }
}