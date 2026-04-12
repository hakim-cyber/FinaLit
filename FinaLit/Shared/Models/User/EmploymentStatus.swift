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

    
    var localizedName: String {
        switch self {
        case .student: return String(localized: "profile.employmentStudent")
        case .employed: return String(localized: "profile.employmentEmployed")
        case .freelancer: return String(localized: "profile.employmentFreelancer")
        case .businessOwner: return String(localized: "profile.employmentBusinessOwner")
        }
    }

    var description: String {
        switch self {
        case .student:
            return String(localized: "profile.employmentStudentDesc")
        case .employed:
            return String(localized: "profile.employmentEmployedDesc")
        case .freelancer:
            return String(localized: "profile.employmentFreelancerDesc")
        case .businessOwner:
            return String(localized: "profile.employmentBusinessOwnerDesc")
        }
    }
}
