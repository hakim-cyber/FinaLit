//
//  NarrativeGoalsEditView.swift
//  FinaLit
//

import SwiftUI

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

    private var appLanguage: AppLanguage {
        session.currentAppLanguage
    }

    private func localized(_ key: String, _ arguments: CVarArg...) -> String {
        L10n.tr(key, language: appLanguage, arguments: arguments)
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
            errorMessage = localized("Session expired. Please log in again.")
            return
        }

        let trimmedShort = settingsTrimmed(shortTermGoal)
        let trimmedLong = settingsTrimmed(longTermGoal)
        guard !trimmedShort.isEmpty, !trimmedLong.isEmpty else {
            errorMessage = localized("Both goals are required.")
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
                successMessage = localized("Goals updated.")
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
