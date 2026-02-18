//
//  User.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String           // Firebase UID
    var email: String
    var name: String
    var createdAt: Date
    var profile: UserProfile?
    var financialProfile: FinancialProfile?
    var behaviorProfile: BehaviorProfile?
    
    // Computed: onboarding complete only if all 3 profiles exist
    var hasCompletedOnboarding: Bool {
        profile != nil && financialProfile != nil && behaviorProfile != nil
    }
}
