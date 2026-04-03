//
//  UserProfile.swift
//  FinaLit
//

import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int
    var country: String
    var employmentStatus: EmploymentStatus
    var monthlyIncome: Double
    var incomeStability: IncomeStability
}
