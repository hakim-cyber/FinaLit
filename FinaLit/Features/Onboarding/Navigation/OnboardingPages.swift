//
//  OnboardingPages.swift
//  FinaLit
//
//  Created by aplle on 2/18/26.
//


// OnboardingPages.swift
// Features/Onboarding/Navigation/

import SwiftUI

enum OnboardingPages: Coordinatable {

    case personalInfo
    case employmentStatus
    case incomeAndStability
    case monthlyExpenses
    case savingsAndEmergencyFund
    case debt
    case riskAndInvesting
    case shortTermGoal
    case longTermGoal
    case spendingWeaknesses
    case hobbies
    case knowledgeLevel
    // ── Add new onboarding steps here ─────────────────────────
    // case newStep

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .personalInfo:              return "onboarding.personalInfo"
        case .employmentStatus:          return "onboarding.employmentStatus"
        case .incomeAndStability:        return "onboarding.incomeAndStability"
        case .monthlyExpenses:           return "onboarding.monthlyExpenses"
        case .savingsAndEmergencyFund:   return "onboarding.savingsAndEmergencyFund"
        case .debt:                      return "onboarding.debt"
        case .riskAndInvesting:          return "onboarding.riskAndInvesting"
        case .shortTermGoal:             return "onboarding.shortTermGoal"
        case .longTermGoal:              return "onboarding.longTermGoal"
        case .spendingWeaknesses:        return "onboarding.spendingWeaknesses"
        case .hobbies:                   return "onboarding.hobbies"
        case .knowledgeLevel:            return "onboarding.knowledgeLevel"
        }
    }

    // MARK: - Step info (for progress bar in views)
    var stepNumber: Int {
        switch self {
        case .personalInfo:            return 1
        case .employmentStatus:        return 2
        case .incomeAndStability:      return 3
        case .monthlyExpenses:         return 4
        case .savingsAndEmergencyFund: return 5
        case .debt:                    return 6
        case .riskAndInvesting:        return 7
        case .shortTermGoal:           return 8
        case .longTermGoal:            return 9
        case .spendingWeaknesses:      return 10
        case .hobbies:                 return 11
        case .knowledgeLevel:          return 12
        }
    }
    static let totalSteps = 12

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .personalInfo:              OnboardingPersonalInfoView()
        case .employmentStatus:          OnboardingEmploymentStatusView()
        case .incomeAndStability:        OnboardingIncomeStabilityView()
        case .monthlyExpenses:           OnboardingExpensesView()
        case .savingsAndEmergencyFund:   OnboardingSavingsEmergencyView()
        case .debt:                      OnboardingDebtView()
        case .riskAndInvesting:          OnboardingRiskInterestView()
        case .shortTermGoal:             OnboardingShortTermGoalView()
        case .longTermGoal:              OnboardingLongTermGoalView()
        case .spendingWeaknesses:        OnboardingSpendingWeaknessesView()
        case .hobbies:                   OnboardingHobbiesView()
        case .knowledgeLevel:            OnboardingKnowledgeLevelView()
        }
    }
}
