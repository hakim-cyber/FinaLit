//
//  User.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String? // Firestore document ID (matches Firebase Auth UID)
    var email: String
    var name: String
    var createdAt: Date
    var profile: UserProfile?
    var isAdmin:          Bool = false
    var financialProfile: FinancialProfile?
    var behaviorProfile: BehaviorProfile?
    var preferences: UserPreferences?
    var financialSummaryLastUpdated: Date?  // know when snapshot was last computed
    var monthlyBudgetGoal: Double?          // optional: user sets a monthly spend limit

    init(
        id: String? = nil,
        email: String,
        name: String,
        createdAt: Date,
        profile: UserProfile? = nil,
        financialProfile: FinancialProfile? = nil,
        behaviorProfile: BehaviorProfile? = nil,
        preferences: UserPreferences? = nil,
        financialSummaryLastUpdated: Date? = nil,
        monthlyBudgetGoal: Double? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.profile = profile
        self.financialProfile = financialProfile
        self.behaviorProfile = behaviorProfile
        self.preferences = preferences
        self.financialSummaryLastUpdated = financialSummaryLastUpdated
        self.monthlyBudgetGoal = monthlyBudgetGoal
    }
    
    // Computed: onboarding complete only if all 3 profiles exist
    var hasCompletedOnboarding: Bool {
        profile != nil && financialProfile != nil && behaviorProfile != nil
    }
}
