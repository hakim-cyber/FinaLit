//
//  UserProfile.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// UserProfile.swift
// Shared/Models/
// Filled during Onboarding Step 1 — Personal Info

import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int
    var country: String
    var employmentStatus: EmploymentStatus
    var monthlyIncome: Double
    var incomeStability: IncomeStability
}

enum EmploymentStatus: String, Codable, CaseIterable, Identifiable {
    case student      = "Student"
    case employed     = "Employed"
    case freelancer   = "Freelancer"
    case businessOwner = "Business Owner"
    
    var id: String { rawValue }
}

enum IncomeStability: String, Codable, CaseIterable, Identifiable {
    case stable   = "Stable"
    case variable = "Variable"
    
    var id: String { rawValue }
}