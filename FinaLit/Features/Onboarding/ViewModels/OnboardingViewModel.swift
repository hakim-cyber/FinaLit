//
//  OnboardingViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// OnboardingViewModel.swift
// Features/Onboarding/ViewModels/

import SwiftUI

@Observable
class OnboardingViewModel {

    // MARK: - Step 1: Personal Info
    var name:             String           = ""
    var age:              String           = ""        // String for TextField, convert on save
    var country:          String           = ""
    var employmentStatus: EmploymentStatus = .employed
    var monthlyIncome:    String           = ""
    var incomeStability:  IncomeStability  = .stable

    // MARK: - Step 2: Financial Status
    var monthlyFixedExpenses:    String = ""
    var monthlyVariableExpenses: String = ""
    var currentSavings:          String = ""
    var hasDebt:                 Bool   = false
    var debtAmount:              String = ""
    var emergencyFundMonths:     Int    = 0

    // MARK: - Step 3: Goals & Risk
    var riskTolerance:          RiskTolerance  = .medium
    var shortTermGoal:          String         = ""
    var longTermGoal:           String         = ""
    var interestedInInvesting:  Bool           = false
    var knowledgeLevel:         KnowledgeLevel = .beginner

    // MARK: - Step 4: Lifestyle
    var hobbies:            [String]          = []
    var spendingWeaknesses: [SpendingCategory] = []

    // MARK: - UI State
    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    // MARK: - Validation per step
    var isStep1Valid: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        Int(age) != nil &&
        !country.isEmpty &&
        !monthlyIncome.isEmpty &&
        Double(monthlyIncome) != nil
    }

    var isStep2Valid: Bool {
        !monthlyFixedExpenses.isEmpty &&
        !monthlyVariableExpenses.isEmpty &&
        !currentSavings.isEmpty &&
        (!hasDebt || !debtAmount.isEmpty)   // if hasDebt, debtAmount required
    }

    var isStep3Valid: Bool {
        !shortTermGoal.isEmpty && !longTermGoal.isEmpty
    }

    var isStep4Valid: Bool {
        !spendingWeaknesses.isEmpty         // at least 1 weakness selected
    }

    // MARK: - Dependencies
    private let dbService: DatabaseService
    private let session:   UserSession

    init(dbService: DatabaseService, session: UserSession) {
        self.dbService = dbService
        self.session   = session
    }

    // MARK: - Step 1 Save
    func savePersonalInfo() async -> Bool {
        guard isStep1Valid else { return false }
        guard let uid = session.user?.id else { return false }

        isLoading = true
        defer { isLoading = false }

        let profile = UserProfile(
            name:             name.trimmingCharacters(in: .whitespaces),
            age:              Int(age) ?? 0,
            country:          country,
            employmentStatus: employmentStatus,
            monthlyIncome:    Double(monthlyIncome) ?? 0,
            incomeStability:  incomeStability
        )

        do {
            try await dbService.saveUserProfile(profile, uid: uid)
            session.updateProfile(profile)   // update local session immediately
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Step 2 Save
    func saveFinancialStatus() async -> Bool {
        guard isStep2Valid else { return false }
        guard let uid = session.user?.id else { return false }

        isLoading = true
        defer { isLoading = false }

        // Build partial FinancialProfile — goals/risk added in step 3
        // We save what we have, step 3 will update the same document field
        let partial = FinancialProfile(
            monthlyFixedExpenses:    Double(monthlyFixedExpenses)    ?? 0,
            monthlyVariableExpenses: Double(monthlyVariableExpenses) ?? 0,
            currentSavings:          Double(currentSavings)          ?? 0,
            hasDebt:                 hasDebt,
            debtAmount:              hasDebt ? Double(debtAmount) : nil,
            emergencyFundMonths:     emergencyFundMonths,
            riskTolerance:           .medium,       // placeholder, set in step 3
            shortTermGoal:           "",            // placeholder, set in step 3
            longTermGoal:            "",            // placeholder, set in step 3
            interestedInInvesting:   false,         // placeholder, set in step 3
            knowledgeLevel:          .beginner      // placeholder, set in step 3
        )

        do {
            try await dbService.saveFinancialProfile(partial, uid: uid)
            session.updateFinancialProfile(partial)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Step 3 Save
    func saveGoalsAndRisk() async -> Bool {
        guard isStep3Valid else { return false }
        guard let uid = session.user?.id else { return false }

        isLoading = true
        defer { isLoading = false }

        // Now build the complete FinancialProfile with step 2 + step 3 data
        let complete = FinancialProfile(
            monthlyFixedExpenses:    Double(monthlyFixedExpenses)    ?? 0,
            monthlyVariableExpenses: Double(monthlyVariableExpenses) ?? 0,
            currentSavings:          Double(currentSavings)          ?? 0,
            hasDebt:                 hasDebt,
            debtAmount:              hasDebt ? Double(debtAmount) : nil,
            emergencyFundMonths:     emergencyFundMonths,
            riskTolerance:           riskTolerance,
            shortTermGoal:           shortTermGoal,
            longTermGoal:            longTermGoal,
            interestedInInvesting:   interestedInInvesting,
            knowledgeLevel:          knowledgeLevel
        )

        do {
            try await dbService.saveFinancialProfile(complete, uid: uid)
            session.updateFinancialProfile(complete)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Step 4 Save + Complete
    func saveLifestyleAndComplete() async -> Bool {
        guard isStep4Valid else { return false }
        guard let uid = session.user?.id else { return false }

        isLoading = true
        defer { isLoading = false }

        let profile = BehaviorProfile(
            topHobbies:          hobbies,
            spendingWeaknesses:  spendingWeaknesses
        )

        do {
            try await dbService.saveBehaviorProfile(profile, uid: uid)
            session.updateBehaviorProfile(profile)
            // All 3 profiles saved → hasCompletedOnboarding = true
            // RootView reacts automatically → shows RootTabView
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}