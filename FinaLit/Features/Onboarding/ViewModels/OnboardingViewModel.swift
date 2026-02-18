//
//  OnboardingViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//

import SwiftUI

@Observable
class OnboardingViewModel {

    // MARK: - Step 1: Name + Age + Country
    var name: String = ""
    var age: Double = 22
    var country: String = ""

    // MARK: - Step 2: Employment
    var employmentStatus: EmploymentStatus = .employed

    // MARK: - Step 3: Income + Stability
    var monthlyIncome: Double = 2500
    var incomeStability: IncomeStability = .stable

    // MARK: - Step 4: Expenses
    var monthlyFixedExpenses: Double = 1200
    var monthlyVariableExpenses: Double = 600

    // MARK: - Step 5: Savings + Emergency Fund
    var currentSavings: Double = 1000
    var emergencyFundMonths: Int = 0

    // MARK: - Step 6: Debt
    var hasDebt: Bool = false
    var debtAmount: Double = 0

    // MARK: - Step 7: Risk + Investing Interest
    var riskTolerance: RiskTolerance = .medium
    var interestedInInvesting: Bool = true

    // MARK: - Step 8 + 9: Goals
    var shortTermGoal: String = ""
    var longTermGoal: String = ""

    // MARK: - Step 10 + 11: Behavior
    var spendingWeaknesses: [SpendingCategory] = []
    var selectedHobbies: [String] = []
    var isOtherHobbySelected: Bool = false
    var customHobby: String = ""

    // MARK: - Step 12: Knowledge
    var knowledgeLevel: KnowledgeLevel = .beginner

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Limits
    let maxWeaknessSelections = 3
    let maxHobbySelections = 3

    // MARK: - Dependencies
    private let dbService: DatabaseService
    private let session: UserSession

    init(dbService: DatabaseService, session: UserSession) {
        self.dbService = dbService
        self.session = session
    }

    // MARK: - Validation
    var isStep1Valid: Bool {
        !trim(name).isEmpty && !trim(country).isEmpty && age >= 13
    }

    var isStep3Valid: Bool {
        monthlyIncome > 0
    }

    var isStep4Valid: Bool {
        monthlyFixedExpenses + monthlyVariableExpenses > 0
    }

    var isStep6Valid: Bool {
        !hasDebt || debtAmount > 0
    }

    var isStep8Valid: Bool {
        !trim(shortTermGoal).isEmpty
    }

    var isStep9Valid: Bool {
        !trim(longTermGoal).isEmpty
    }

    var isStep10Valid: Bool {
        !spendingWeaknesses.isEmpty
    }

    var normalizedHobbies: [String] {
        var hobbies = selectedHobbies
        if isOtherHobbySelected {
            let custom = trim(customHobby)
            if !custom.isEmpty {
                hobbies.append(custom)
            }
        }

        // Preserve order, drop duplicates, cap to 3
        var seen = Set<String>()
        let unique = hobbies.filter { seen.insert($0).inserted }
        return Array(unique.prefix(maxHobbySelections))
    }

    var isStep11Valid: Bool {
        !normalizedHobbies.isEmpty
    }

    // MARK: - Actions
    func clearError() {
        errorMessage = nil
    }

    func toggleWeakness(_ weakness: SpendingCategory) {
        clearError()

        if let index = spendingWeaknesses.firstIndex(of: weakness) {
            spendingWeaknesses.remove(at: index)
            return
        }

        guard spendingWeaknesses.count < maxWeaknessSelections else {
            errorMessage = "You can select up to \(maxWeaknessSelections) spending categories."
            return
        }
        spendingWeaknesses.append(weakness)
    }

    func toggleHobby(_ hobby: String) {
        clearError()

        if let index = selectedHobbies.firstIndex(of: hobby) {
            selectedHobbies.remove(at: index)
            return
        }

        guard selectedHobbies.count < maxHobbySelections else {
            errorMessage = "You can select up to \(maxHobbySelections) hobbies."
            return
        }
        selectedHobbies.append(hobby)
    }

    // MARK: - Step Saves
    func saveStep1PersonalInfo() async -> Bool {
        guard isStep1Valid else {
            errorMessage = "Please enter your name, age, and country."
            return false
        }
        return await saveUserProfileProgress()
    }

    func saveStep2Employment() async -> Bool {
        await saveUserProfileProgress()
    }

    func saveStep3Income() async -> Bool {
        guard isStep3Valid else {
            errorMessage = "Please set your monthly income."
            return false
        }
        return await saveUserProfileProgress()
    }

    func saveStep4Expenses() async -> Bool {
        guard isStep4Valid else {
            errorMessage = "Please set at least one expense value."
            return false
        }
        return await saveFinancialProfileProgress()
    }

    func saveStep5Savings() async -> Bool {
        await saveFinancialProfileProgress()
    }

    func saveStep6Debt() async -> Bool {
        guard isStep6Valid else {
            errorMessage = "Please enter your total debt amount."
            return false
        }
        return await saveFinancialProfileProgress()
    }

    func saveStep7Risk() async -> Bool {
        await saveFinancialProfileProgress()
    }

    func saveStep8ShortTermGoal() async -> Bool {
        guard isStep8Valid else {
            errorMessage = "Please set a short-term goal."
            return false
        }
        return await saveFinancialProfileProgress()
    }

    func saveStep9LongTermGoal() async -> Bool {
        guard isStep9Valid else {
            errorMessage = "Please set a long-term goal."
            return false
        }
        return await saveFinancialProfileProgress()
    }

    func validateStep10Weaknesses() -> Bool {
        guard isStep10Valid else {
            errorMessage = "Select at least one spending weakness."
            return false
        }
        return true
    }

    func validateStep11Hobbies() -> Bool {
        guard isStep11Valid else {
            errorMessage = "Select at least one hobby."
            return false
        }
        return true
    }

    func completeOnboarding() async -> Bool {
        guard isStep10Valid else {
            errorMessage = "Select at least one spending weakness."
            return false
        }

        guard isStep11Valid else {
            errorMessage = "Select at least one hobby."
            return false
        }

        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let financialProfile = makeFinancialProfile()
            let behaviorProfile = BehaviorProfile(
                topHobbies: normalizedHobbies,
                spendingWeaknesses: spendingWeaknesses
            )

            try await dbService.saveFinancialProfile(financialProfile, uid: uid)
            try await dbService.saveBehaviorProfile(behaviorProfile, uid: uid)

            session.updateFinancialProfile(financialProfile)
            session.updateBehaviorProfile(behaviorProfile)

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Private Saves
    private func saveUserProfileProgress() async -> Bool {
        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let profile = UserProfile(
                name: trim(name),
                age: Int(age.rounded()),
                country: trim(country),
                employmentStatus: employmentStatus,
                monthlyIncome: monthlyIncome,
                incomeStability: incomeStability
            )

            try await dbService.saveUserProfile(profile, uid: uid)
            session.updateProfile(profile)

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func saveFinancialProfileProgress() async -> Bool {
        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let profile = makeFinancialProfile()
            try await dbService.saveFinancialProfile(profile, uid: uid)
            session.updateFinancialProfile(profile)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func makeFinancialProfile() -> FinancialProfile {
        FinancialProfile(
            monthlyFixedExpenses: monthlyFixedExpenses,
            monthlyVariableExpenses: monthlyVariableExpenses,
            currentSavings: currentSavings,
            hasDebt: hasDebt,
            debtAmount: hasDebt ? debtAmount : nil,
            emergencyFundMonths: emergencyFundMonths,
            riskTolerance: riskTolerance,
            shortTermGoal: trim(shortTermGoal),
            longTermGoal: trim(longTermGoal),
            interestedInInvesting: interestedInInvesting,
            knowledgeLevel: knowledgeLevel
        )
    }

    private func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
