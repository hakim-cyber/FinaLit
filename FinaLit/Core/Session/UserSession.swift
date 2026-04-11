//
//  UserSession.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// UserSession.swift
// Core/Session/

import Foundation
import Observation

@Observable
class UserSession {
    var user: User?
    var isRestoringSession: Bool = true
    
    var isAuthenticated: Bool { user != nil }
    
    var hasCompletedOnboarding: Bool {
        user?.hasCompletedOnboarding ?? false
    }
    
    // Called by AuthViewModel after login/register
    func setUser(_ user: User) {
        self.user = user
    }
    
    // Called after each onboarding step saves to Firestore
    func updateProfile(_ profile: UserProfile) {
        user?.profile = profile
    }

    func updateName(_ name: String) {
        user?.name = name
    }
    
    func updateFinancialProfile(_ profile: FinancialProfile) {
        user?.financialProfile = profile
    }
    
    func updateBehaviorProfile(_ profile: BehaviorProfile) {
        user?.behaviorProfile = profile
    }

    func updatePreferences(_ preferences: UserPreferences) {
        user?.preferences = preferences
    }
    
    func signOut() {
        self.user = nil
    }

    func finishSessionRestore() {
        isRestoringSession = false
    }
}
