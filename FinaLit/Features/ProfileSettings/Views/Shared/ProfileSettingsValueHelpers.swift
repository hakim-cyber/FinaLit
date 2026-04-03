//
//  ProfileSettingsValueHelpers.swift
//  FinaLit
//

import Foundation

func settingsTrimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func settingsEditableAmount(_ value: Double) -> String {
    value == 0 ? "" : formatAmount(value)
}

func fallbackUserProfile(from user: User?) -> UserProfile {
    UserProfile(
        name: user?.profile?.name ?? user?.name ?? "",
        age: user?.profile?.age ?? 22,
        country: user?.profile?.country ?? AppRegion.defaultCountry,
        employmentStatus: user?.profile?.employmentStatus ?? .employed,
        monthlyIncome: user?.profile?.monthlyIncome ?? 0,
        incomeStability: user?.profile?.incomeStability ?? .stable
    )
}

func fallbackFinancialProfile(from user: User?) -> FinancialProfile {
    FinancialProfile(
        monthlyFixedExpenses: user?.financialProfile?.monthlyFixedExpenses ?? 0,
        monthlyVariableExpenses: user?.financialProfile?.monthlyVariableExpenses ?? 0,
        currentSavings: user?.financialProfile?.currentSavings ?? 0,
        hasDebt: user?.financialProfile?.hasDebt ?? false,
        debtAmount: user?.financialProfile?.debtAmount,
        emergencyFundMonths: user?.financialProfile?.emergencyFundMonths ?? 0,
        riskTolerance: user?.financialProfile?.riskTolerance ?? .medium,
        shortTermGoal: user?.financialProfile?.shortTermGoal ?? "",
        longTermGoal: user?.financialProfile?.longTermGoal ?? "",
        interestedInInvesting: user?.financialProfile?.interestedInInvesting ?? false,
        knowledgeLevel: user?.financialProfile?.knowledgeLevel ?? .beginner
    )
}
