//
//  LearningLanguageMenu.swift
//  FinaLit
//

import SwiftUI

struct LearningLanguageMenu: View {
    @Environment(AppPreferencesStore.self) private var preferences

    private var followAppLabel: String {
        L10n.tr(
            "Follow App (%@)",
            language: preferences.appLanguage,
            preferences.appLanguage.nativeDisplayName
        )
    }

    var body: some View {
        Menu {
            Button {
                preferences.setLearningLanguagePreference(.followApp)
            } label: {
                if preferences.learningLanguagePreference == .followApp {
                    Label(followAppLabel, systemImage: "checkmark")
                } else {
                    Text(followAppLabel)
                }
            }

            Divider()

            ForEach(AppLanguage.allCases) { language in
                Button {
                    preferences.setLearningLanguagePreference(.specific(language))
                } label: {
                    if preferences.learningContentLanguageOverride == language {
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
