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
import SwiftUI

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
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .food:          return L10n.Main.categoryFood
        case .transport:     return L10n.Main.categoryTransport
        case .rent:          return L10n.Main.categoryRent
        case .entertainment: return L10n.Main.categoryEntertainment
        case .education:     return L10n.Main.categoryEducation
        case .health:        return L10n.Main.categoryHealth
        case .tech:          return L10n.Main.categoryTech
        case .clothes:       return L10n.Main.categoryClothes
        case .travel:        return L10n.Main.categoryTravel
        case .other:         return L10n.Main.categoryOther
        }
    }
    
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