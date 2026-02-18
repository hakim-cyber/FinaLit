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
    var description: String {
            switch self {
            case .student:
                return "Currently studying, no regular full-time income"
            case .employed:
                return "Working full-time or part-time with a fixed salary"
            case .freelancer:
                return "Self-employed with variable or project-based income"
            case .businessOwner:
                return "Owns or runs a business with business income"
            }
        }
}

enum IncomeStability: String, Codable, CaseIterable, Identifiable {
    case stable   = "Stable"
    case variable = "Variable"
    
    var id: String { rawValue }
}
