//
//  UserPreferences.swift
//  FinaLit
//

import Foundation

struct UserPreferences: Codable, Equatable {
    var appLanguage: AppLanguage?
    var learningContentLanguageOverride: AppLanguage?

    init(
        appLanguage: AppLanguage? = nil,
        learningContentLanguageOverride: AppLanguage? = nil
    ) {
        self.appLanguage = appLanguage
        self.learningContentLanguageOverride = learningContentLanguageOverride
    }

    var resolvedAppLanguage: AppLanguage {
        appLanguage ?? .default
    }

    func effectiveLearningLanguage(fallbackAppLanguage: AppLanguage? = nil) -> AppLanguage {
        learningContentLanguageOverride ?? appLanguage ?? fallbackAppLanguage ?? .default
    }
}
