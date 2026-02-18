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
    case financialStatus
    case goalsAndRisk
    case lifestyle
    // ── Add new onboarding steps here ─────────────────────────
    // case newStep

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .personalInfo:    return "onboarding.personalInfo"
        case .financialStatus: return "onboarding.financialStatus"
        case .goalsAndRisk:    return "onboarding.goalsAndRisk"
        case .lifestyle:       return "onboarding.lifestyle"
        }
    }

    // MARK: - Step info (for progress bar in views)
    var stepNumber: Int {
        switch self {
        case .personalInfo:    return 1
        case .financialStatus: return 2
        case .goalsAndRisk:    return 3
        case .lifestyle:       return 4
        }
    }
    static let totalSteps = 4

    // MARK: - View
    @ViewBuilder
    var body: some View {
        switch self {
        case .personalInfo:    Text("Step 1 - Personal Info")    // replace with real view
        case .financialStatus: Text("Step 2 - Financial Status") // replace with real view
        case .goalsAndRisk:    Text("Step 3 - Goals & Risk")     // replace with real view
        case .lifestyle:       Text("Step 4 - Lifestyle")        // replace with real view
        }
    }
}