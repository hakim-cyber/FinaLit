//
//  SettingsPages.swift
//  FinaLit
//
//  Created by Codex on 2/21/26.
//

import SwiftUI

enum SettingsPages: Coordinatable {
    case home
    case personalInfo
    case financialProfile
    case goals

    var id: String {
        switch self {
        case .home:             return "settings.home"
        case .personalInfo:     return "settings.personalInfo"
        case .financialProfile: return "settings.financialProfile"
        case .goals:            return "settings.goals"
        }
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .home:
            ProfileSettingsHomeView()
        case .personalInfo:
            PersonalInfoEditView()
        case .financialProfile:
            FinancialProfileEditView()
        case .goals:
            NarrativeGoalsEditView()
        }
    }
}
