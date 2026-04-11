//
//  AppPreferencesStore.swift
//  FinaLit
//

import Foundation
import Observation

@MainActor
@Observable
final class AppPreferencesStore {
    private enum StorageKey {
        static let appLanguage = "finalit.preferences.appLanguage"
        static let learningLanguage = "finalit.preferences.learningContentLanguageOverride"
    }

    var appLanguage: AppLanguage
    var learningContentLanguageOverride: AppLanguage?

    private let defaults: UserDefaults
    private let dbService: DatabaseService
    private let session: UserSession
    private var lastHandledUserID: String?

    init(
        dbService: DatabaseService,
        session: UserSession,
        defaults: UserDefaults = .standard
    ) {
        self.dbService = dbService
        self.session = session
        self.defaults = defaults
        appLanguage = AppLanguage(
            rawValue: defaults.string(forKey: StorageKey.appLanguage) ?? ""
        ) ?? .default
        learningContentLanguageOverride = AppLanguage(
            rawValue: defaults.string(forKey: StorageKey.learningLanguage) ?? ""
        )
    }

    var locale: Locale {
        appLanguage.locale
    }

    var effectiveLearningLanguage: AppLanguage {
        learningContentLanguageOverride ?? appLanguage
    }

    var learningLanguagePreference: LearningLanguagePreference {
        if let learningContentLanguageOverride {
            return .specific(learningContentLanguageOverride)
        }

        return .followApp
    }

    func handleSessionUserChanged() {
        let currentUID = session.user?.id

        guard currentUID != lastHandledUserID else { return }
        lastHandledUserID = currentUID

        guard let user = session.user else {
            loadFromLocalDefaults()
            return
        }

        apply(
            user.preferences ?? defaultPreferences(),
            persistToRemoteIfMissing: user.preferences == nil
        )
    }

    func refreshFromCurrentSession() {
        guard let user = session.user else {
            loadFromLocalDefaults()
            return
        }

        apply(
            user.preferences ?? defaultPreferences(),
            persistToRemoteIfMissing: user.preferences == nil
        )
    }

    func setAppLanguage(_ language: AppLanguage) {
        guard appLanguage != language else { return }
        appLanguage = language
        persistLocally()
        persistToSessionAndRemote()
    }

    func setLearningLanguagePreference(_ preference: LearningLanguagePreference) {
        switch preference {
        case .followApp:
            learningContentLanguageOverride = nil
        case .specific(let language):
            learningContentLanguageOverride = language
        }

        persistLocally()
        persistToSessionAndRemote()
    }

    private func defaultPreferences() -> UserPreferences {
        UserPreferences(appLanguage: .default, learningContentLanguageOverride: nil)
    }

    private func apply(_ preferences: UserPreferences, persistToRemoteIfMissing: Bool) {
        appLanguage = preferences.appLanguage ?? .default
        learningContentLanguageOverride = preferences.learningContentLanguageOverride
        persistLocally()
        session.updatePreferences(currentPreferences())

        guard persistToRemoteIfMissing else { return }
        persistToRemote()
    }

    private func loadFromLocalDefaults() {
        appLanguage = AppLanguage(
            rawValue: defaults.string(forKey: StorageKey.appLanguage) ?? ""
        ) ?? .default
        learningContentLanguageOverride = AppLanguage(
            rawValue: defaults.string(forKey: StorageKey.learningLanguage) ?? ""
        )
    }

    private func currentPreferences() -> UserPreferences {
        UserPreferences(
            appLanguage: appLanguage,
            learningContentLanguageOverride: learningContentLanguageOverride
        )
    }

    private func persistLocally() {
        defaults.set(appLanguage.rawValue, forKey: StorageKey.appLanguage)
        defaults.set(learningContentLanguageOverride?.rawValue, forKey: StorageKey.learningLanguage)
    }

    private func persistToSessionAndRemote() {
        session.updatePreferences(currentPreferences())
        persistToRemote()
    }

    private func persistToRemote() {
        guard let uid = session.user?.id else { return }
        let preferences = currentPreferences()

        Task {
            try? await dbService.saveUserPreferences(preferences, uid: uid)
        }
    }
}
