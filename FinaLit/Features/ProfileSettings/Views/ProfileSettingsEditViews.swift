//
//  ProfileSettingsEditViews.swift
//  FinaLit
//
//  Created by Codex on 2/21/26.
//

import SwiftUI

struct PersonalInfoEditView: View {
    @Environment(UserSession.self) private var session
    @Environment(DatabaseService.self) private var dbService

    @State private var name = ""
    @State private var age: Double = 22
    @State private var country = AppRegion.defaultCountry
    @State private var employmentStatus: EmploymentStatus = .employed

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private var canSave: Bool {
        !settingsTrimmed(name).isEmpty &&
        !settingsTrimmed(country).isEmpty &&
        age >= 13 &&
        !isSaving
    }

    var body: some View {
        ProfileSettingsFormScaffold(
            title: "Personal Info",
            subtitle: "Keep your identity and lifestyle context up to date.",
            errorMessage: errorMessage,
            successMessage: successMessage,
            isLoading: isSaving,
            primaryTitle: "Save Changes",
            isPrimaryEnabled: canSave,
            onPrimaryTap: save
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .settingsFieldLabelStyle()
                    TextField("Your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .settingsInputStyle()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (display only)")
                        .settingsFieldLabelStyle()
                    Text(session.user?.email ?? "No email")
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(ProfileSettingsPalette.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ProfileSettingsPalette.border, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Age")
                            .settingsFieldLabelStyle()
                        Spacer()
                        Text("\(Int(age.rounded()))")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ProfileSettingsPalette.accent)
                    }
                    Slider(value: $age, in: 13...80, step: 1)
                        .tint(ProfileSettingsPalette.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .settingsFieldLabelStyle()
                    TextField("Country", text: $country)
                        .textInputAutocapitalization(.words)
                        .settingsInputStyle()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Employment status")
                        .settingsFieldLabelStyle()

                    ForEach(EmploymentStatus.allCases) { status in
                        ProfileSettingsSelectableRow(
                            title: status.rawValue,
                            subtitle: status.description,
                            isSelected: employmentStatus == status,
                            accent: ProfileSettingsPalette.accent
                        ) {
                            employmentStatus = status
                            clearMessages()
                        }
                    }
                }
            }
            .onChange(of: name) { _, _ in clearMessages() }
            .onChange(of: country) { _, _ in clearMessages() }
            .onChange(of: age) { _, _ in clearMessages() }
        }
        .task {
            guard !didLoad else { return }
            didLoad = true

            let profile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            name = profile.name
            age = Double(profile.age)
            country = profile.country
            employmentStatus = profile.employmentStatus
        }
    }

    private func save() {
        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return
        }

        let trimmedName = settingsTrimmed(name)
        let trimmedCountry = settingsTrimmed(country)
        guard !trimmedName.isEmpty, !trimmedCountry.isEmpty else {
            errorMessage = "Name and country are required."
            return
        }

        isSaving = true
        clearMessages()

        Task { @MainActor in
            let currentProfile = session.user?.profile ?? fallbackUserProfile(from: session.user)
            let updatedProfile = UserProfile(
                name: trimmedName,
                age: Int(age.rounded()),
                country: trimmedCountry,
                employmentStatus: employmentStatus,
                monthlyIncome: currentProfile.monthlyIncome,
                incomeStability: currentProfile.incomeStability
            )

            do {
                try dbService.saveUserProfile(updatedProfile, uid: uid)
                try await dbService.updateUser(uid: uid, data: ["name": trimmedName])
                session.updateProfile(updatedProfile)
                session.updateName(trimmedName)
                successMessage = "Personal info updated."
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

struct NarrativeGoalsEditView: View {
    @Environment(UserSession.self) private var session
    @Environment(DatabaseService.self) private var dbService

    @State private var shortTermGoal = ""
    @State private var longTermGoal = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private var canSave: Bool {
        !settingsTrimmed(shortTermGoal).isEmpty &&
        !settingsTrimmed(longTermGoal).isEmpty &&
        !isSaving
    }

    var body: some View {
        ProfileSettingsFormScaffold(
            title: "Goals",
            subtitle: "These narrative goals feed AI context and recommendations.",
            errorMessage: errorMessage,
            successMessage: successMessage,
            isLoading: isSaving,
            primaryTitle: "Save Changes",
            isPrimaryEnabled: canSave,
            onPrimaryTap: save
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Short term goal")
                        .settingsFieldLabelStyle()
                    TextField("Type your short-term goal", text: $shortTermGoal, axis: .vertical)
                        .lineLimit(2...4)
                        .settingsTextAreaStyle()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Long term goal")
                        .settingsFieldLabelStyle()
                    TextField("Type your long-term goal", text: $longTermGoal, axis: .vertical)
                        .lineLimit(2...4)
                        .settingsTextAreaStyle()
                }
            }
            .onChange(of: shortTermGoal) { _, _ in clearMessages() }
            .onChange(of: longTermGoal) { _, _ in clearMessages() }
        }
        .task {
            guard !didLoad else { return }
            didLoad = true

            let financial = session.user?.financialProfile ?? fallbackFinancialProfile(from: session.user)
            shortTermGoal = financial.shortTermGoal
            longTermGoal = financial.longTermGoal
        }
    }

    private func save() {
        guard let uid = session.user?.id else {
            errorMessage = "Session expired. Please log in again."
            return
        }

        let trimmedShort = settingsTrimmed(shortTermGoal)
        let trimmedLong = settingsTrimmed(longTermGoal)
        guard !trimmedShort.isEmpty, !trimmedLong.isEmpty else {
            errorMessage = "Both goals are required."
            return
        }

        isSaving = true
        clearMessages()

        Task { @MainActor in
            let currentFinancial = session.user?.financialProfile ?? fallbackFinancialProfile(from: session.user)
            let updatedFinancial = FinancialProfile(
                monthlyFixedExpenses: currentFinancial.monthlyFixedExpenses,
                monthlyVariableExpenses: currentFinancial.monthlyVariableExpenses,
                currentSavings: currentFinancial.currentSavings,
                hasDebt: currentFinancial.hasDebt,
                debtAmount: currentFinancial.debtAmount,
                emergencyFundMonths: currentFinancial.emergencyFundMonths,
                riskTolerance: currentFinancial.riskTolerance,
                shortTermGoal: trimmedShort,
                longTermGoal: trimmedLong,
                interestedInInvesting: currentFinancial.interestedInInvesting,
                knowledgeLevel: currentFinancial.knowledgeLevel
            )

            do {
                try dbService.saveFinancialProfile(updatedFinancial, uid: uid)
                session.updateFinancialProfile(updatedFinancial)
                successMessage = "Goals updated."
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
