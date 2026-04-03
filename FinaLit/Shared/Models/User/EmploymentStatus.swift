//
//  EmploymentStatus.swift
//  FinaLit
//

import Foundation

enum EmploymentStatus: String, Codable, CaseIterable, Identifiable {
    case student = "Student"
    case employed = "Employed"
    case freelancer = "Freelancer"
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
