//
//  UserPreferences.swift
//  FinaLit
//

import Foundation

struct UserPreferences: Codable, Equatable {
    var legacyLanguage: AppLanguage?
    var learningContentLanguage: AppLanguage?

    enum CodingKeys: String, CodingKey {
        case legacyLanguage = "appLanguage"
        case learningContentLanguage = "learningContentLanguageOverride"
    }

    init(
        legacyLanguage: AppLanguage? = nil,
        learningContentLanguage: AppLanguage? = nil
    ) {
        self.legacyLanguage = legacyLanguage
        self.learningContentLanguage = learningContentLanguage
    }

    func effectiveLearningLanguage(fallbackAppLanguage: AppLanguage? = nil) -> AppLanguage {
        learningContentLanguage ?? legacyLanguage ?? fallbackAppLanguage ?? .default
    }
}
