//
//  LearningLanguageMenu.swift
//  FinaLit
//

import SwiftUI

struct LearningLanguageMenu: View {
    @Environment(AppPreferencesStore.self) private var preferences

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    preferences.setLearningLanguage(language)
                } label: {
                    if preferences.effectiveLearningLanguage == language {
                        Label(language.nativeDisplayName, systemImage: "checkmark")
                    } else {
                        Text(language.nativeDisplayName)
                    }
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(AppTheme.Typography.toolbarIcon)
        }
    }
}
