//
//  OnboardingViewModel.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//

import SwiftUI

@Observable
class OnboardingViewModel {
    struct DebtEntry: Identifiable, Equatable {
        let id: UUID
        var name: String
        var amountText: String

        init(id: UUID = UUID(), name: String = "", amountText: String = "") {
            self.id = id
            self.name = name
            self.amountText = amountText
        }
    }

    // MARK: - Step 1: Name + Age + Country
    var name: String = ""
    var age: Double = 22
    var country: String = AppRegion.defaultCountry

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
    var debtEntries: [DebtEntry] = []
    var totalDebtAmount: Double {
        debtEntries
            .compactMap { parseMonetaryInput($0.amountText) }
            .filter { $0 > 0 }
            .reduce(0, +)
    }

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
        guard hasDebt else { return true }
        let entries = normalizedDebtEntries
        guard !entries.isEmpty else { return false }
        return entries.allSatisfy {
            !trim($0.name).isEmpty &&
            (parseMonetaryInput($0.amountText) ?? 0) > 0
        }
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

    // MARK: - Step 6 Helpers
    func setHasDebt(_ enabled: Bool) {
        hasDebt = enabled
        if enabled {
            if debtEntries.isEmpty {
                debtEntries = [DebtEntry(name: "Credit Card")]
            }
        } else {
            debtEntries = []
        }
        clearError()
    }

    func addDebtEntry() {
        debtEntries.append(DebtEntry())
        clearError()
    }

    func removeDebtEntry(_ id: UUID) {
        debtEntries.removeAll { $0.id == id }
        clearError()
    }

    func debtEntryName(_ id: UUID) -> String {
        debtEntries.first(where: { $0.id == id })?.name ?? ""
    }

    func debtEntryAmountText(_ id: UUID) -> String {
        debtEntries.first(where: { $0.id == id })?.amountText ?? ""
    }

    func updateDebtEntryName(_ id: UUID, value: String) {
        guard let index = debtEntries.firstIndex(where: { $0.id == id }) else { return }
        debtEntries[index].name = value
        clearError()
    }

    func updateDebtEntryAmount(_ id: UUID, value: String) {
        guard let index = debtEntries.firstIndex(where: { $0.id == id }) else { return }
        debtEntries[index].amountText = value
        clearError()
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
            errorMessage = hasDebt
                ? "Add at least one debt with account name and amount."
                : "Please confirm your debt status."
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

            try dbService.saveFinancialProfile(financialProfile, uid: uid)
            try dbService.saveBehaviorProfile(behaviorProfile, uid: uid)

            if hasDebt {
                let debtAccounts = buildDebtAccounts()
                if !debtAccounts.isEmpty {
                    let existingDebtAccounts = try await dbService.fetchDebtAccounts(uid: uid)
                    if existingDebtAccounts.isEmpty {
                        for debtAccount in debtAccounts {
                            try dbService.createDebtAccount(debtAccount, uid: uid)
                        }
                    }
                }
            }

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

            try dbService.saveUserProfile(profile, uid: uid)
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
            try dbService.saveFinancialProfile(profile, uid: uid)
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
            debtAmount: hasDebt ? totalDebtAmount : nil,
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

    private var normalizedDebtEntries: [DebtEntry] {
        debtEntries.filter {
            !trim($0.name).isEmpty || !trim($0.amountText).isEmpty
        }
    }

    private func buildDebtAccounts() -> [DebtAccount] {
        let now = Date()
        return normalizedDebtEntries.compactMap { entry in
            let name = trim(entry.name)
            guard !name.isEmpty,
                  let amount = parseMonetaryInput(entry.amountText),
                  amount > 0 else { return nil }

            return DebtAccount(
                id: UUID().uuidString,
                name: name,
                currentBalance: amount,
                annualInterestRate: nil,
                minimumMonthlyPayment: nil,
                createdAt: now,
                updatedAt: now,
                isClosed: false
            )
        }
    }
}
