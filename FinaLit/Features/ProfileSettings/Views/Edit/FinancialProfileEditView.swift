//
//  FinancialProfileEditView.swift
//  FinaLit
//

import SwiftUI

struct FinancialProfileEditView: View {
    @Environment(UserSession.self) private var session
    @Environment(DatabaseService.self) private var dbService

    @State private var monthlyIncome = ""
    @State private var incomeStability: IncomeStability = .stable
    @State private var fixedExpenses = ""
    @State private var variableExpenses = ""
    @State private var currentSavings = ""
    @State private var hasDebt = false
    @State private var debtAmount = ""
    @State private var riskTolerance: RiskTolerance = .medium
    @State private var interestedInInvesting = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private var canSave: Bool {
        !monthlyIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        ProfileSettingsFormScaffold(
            title: "Financial Profile",
            subtitle: "Update your real-world numbers to keep advice relevant.",
            errorMessage: errorMessage,
            successMessage: successMessage,
            isLoading: isSaving,
            primaryTitle: "Save Changes",
            isPrimaryEnabled: canSave,
            onPrimaryTap: save
        ) {
            VStack(alignment: .leading, spacing: 16) {
                settingsMoneyField(title: "Monthly income", text: $monthlyIncome)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Income stability")
                        .settingsFieldLabelStyle()

                    HStack(spacing: 10) {
                        ProfileSettingsTogglePill(
                            title: "Stable",
                            isSelected: incomeStability == .stable,
                            tint: ProfileSettingsPalette.accent
                        ) {
                            incomeStability = .stable
                            clearMessages()
                        }

                        ProfileSettingsTogglePill(
                            title: "Variable",
                            isSelected: incomeStability == .variable,
                            tint: .orange
                        ) {
                            incomeStability = .variable
                            clearMessages()
                        }
                    }
                }

                settingsMoneyField(title: "Fixed expenses", text: $fixedExpenses)
                settingsMoneyField(title: "Variable expenses", text: $variableExpenses)
                settingsMoneyField(title: "Current savings", text: $currentSavings)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Do you currently have debt?")
                        .settingsFieldLabelStyle()

                    HStack(spacing: 10) {
                        ProfileSettingsTogglePill(
                            title: "No debt",
                            isSelected: !hasDebt,
                            tint: .green
                        ) {
                            hasDebt = false
                            debtAmount = ""
                            clearMessages()
                        }

                        ProfileSettingsTogglePill(
                            title: "I have debt",
                            isSelected: hasDebt,
                            tint: .red
                        ) {
                            hasDebt = true
                            clearMessages()
                        }
                    }
                }

                if hasDebt {
                    settingsMoneyField(title: "Debt amount", text: $debtAmount)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Risk tolerance")
                        .settingsFieldLabelStyle()

                    ForEach(RiskTolerance.allCases) { option in
                        ProfileSettingsSelectableRow(
                            title: option.rawValue,
                            subtitle: option.description,
                            isSelected: riskTolerance == option,
                            accent: option == .low ? .green : (option == .medium ? .orange : .red)
                        ) {
                            riskTolerance = option
                            clearMessages()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Interested in investing?")
                        .settingsFieldLabelStyle()

                    HStack(spacing: 10) {
                        ProfileSettingsTogglePill(
                            title: "Yes",
                            isSelected: interestedInInvesting,
                            tint: ProfileSettingsPalette.accent
                        ) {
                            interestedInInvesting = true
                            clearMessages()
                        }

                        ProfileSettingsTogglePill(
                            title: "Not now",
                            isSelected: !interestedInInvesting,
                            tint: ProfileSettingsPalette.muted
                        ) {
                            interestedInInvesting = false
                            clearMessages()
                        }
                    }
                }
            }
            .onChange(of: monthlyIncome) { _, _ in clearMessages() }
            .onChange(of: fixedExpenses) { _, _ in clearMessages() }
            .onChange(of: variableExpenses) { _, _ in clearMessages() }
            .onChange(of: currentSavings) { _, _ in clearMessages() }
            .onChange(of: debtAmount) { _, _ in clearMessages() }
        }
        .task {
            guard !didLoad else { return }
            didLoad = true

            let profile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            let financial = session.user?.financialProfile ?? fallbackFinancialProfile(from: session.user)

            monthlyIncome = settingsEditableAmount(profile.monthlyIncome)
            incomeStability = profile.incomeStability
            fixedExpenses = settingsEditableAmount(financial.monthlyFixedExpenses)
            variableExpenses = settingsEditableAmount(financial.monthlyVariableExpenses)
            currentSavings = settingsEditableAmount(financial.currentSavings)
            hasDebt = financial.hasDebt
            debtAmount = settingsEditableAmount(financial.debtAmount ?? 0)
            riskTolerance = financial.riskTolerance
            interestedInInvesting = financial.interestedInInvesting
        }
    }

    private func settingsMoneyField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .settingsFieldLabelStyle()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .settingsInputStyle()
        }
    }

    private func save() {
        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return
        }

        guard let parsedMonthlyIncome = parseMonetaryInput(monthlyIncome), parsedMonthlyIncome > 0 else {
            errorMessage = "Monthly income must be greater than 0."
            return
        }

        let parsedFixedExpenses = max(parseMonetaryInput(fixedExpenses) ?? 0, 0)
        let parsedVariableExpenses = max(parseMonetaryInput(variableExpenses) ?? 0, 0)
        let parsedSavings = max(parseMonetaryInput(currentSavings) ?? 0, 0)

        var parsedDebtAmount: Double?
        if hasDebt {
            guard let value = parseMonetaryInput(debtAmount), value > 0 else {
                errorMessage = "Debt amount must be greater than 0 when debt is enabled."
                return
            }
            parsedDebtAmount = value
        }

        isSaving = true
        clearMessages()

        Task { @MainActor in
            let currentProfile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            let currentFinancial = session.user?.financialProfile ?? fallbackFinancialProfile(from: session.user)

            let updatedProfile = UserProfile(
                name: currentProfile.name,
                age: currentProfile.age,
                country: currentProfile.country,
                employmentStatus: currentProfile.employmentStatus,
                monthlyIncome: parsedMonthlyIncome,
                incomeStability: incomeStability
            )

            let updatedFinancial = FinancialProfile(
                monthlyFixedExpenses: parsedFixedExpenses,
                monthlyVariableExpenses: parsedVariableExpenses,
                currentSavings: parsedSavings,
                hasDebt: hasDebt,
                debtAmount: hasDebt ? parsedDebtAmount : nil,
                emergencyFundMonths: currentFinancial.emergencyFundMonths,
                riskTolerance: riskTolerance,
                shortTermGoal: currentFinancial.shortTermGoal,
                longTermGoal: currentFinancial.longTermGoal,
                interestedInInvesting: interestedInInvesting,
                knowledgeLevel: currentFinancial.knowledgeLevel
            )

            do {
                try dbService.saveUserProfile(updatedProfile, uid: uid)
                try dbService.saveFinancialProfile(updatedFinancial, uid: uid)
                session.updateProfile(updatedProfile)
                session.updateFinancialProfile(updatedFinancial)
                successMessage = "Financial profile updated."
            } catch {
                errorMessage = error.localizedDescription
            }

            isSaving = false
        }
    }

    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
