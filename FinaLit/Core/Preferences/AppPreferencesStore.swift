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
        static let legacyAppLanguage = "finalit.preferences.appLanguage"
        static let learningLanguage = "finalit.preferences.learningContentLanguageOverride"
    }

    var learningContentLanguage: AppLanguage

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
        learningContentLanguage = Self.languageFromDefaults(defaults)
    }

    var effectiveLearningLanguage: AppLanguage {
        learningContentLanguage
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

    func setLearningLanguage(_ language: AppLanguage) {
        guard learningContentLanguage != language else { return }
        learningContentLanguage = language
        persistLocally()
        persistToSessionAndRemote()
    }

    private func defaultPreferences() -> UserPreferences {
        UserPreferences(learningContentLanguage: .default)
    }

    private func apply(_ preferences: UserPreferences, persistToRemoteIfMissing: Bool) {
        learningContentLanguage = preferences.learningContentLanguage
            ?? preferences.legacyLanguage
            ?? .default
        persistLocally()
        session.updatePreferences(currentPreferences())

        guard persistToRemoteIfMissing else { return }
        persistToRemote()
    }

    private func loadFromLocalDefaults() {
        learningContentLanguage = Self.languageFromDefaults(defaults)
    }

    private func currentPreferences() -> UserPreferences {
        UserPreferences(
            legacyLanguage: nil,
            learningContentLanguage: learningContentLanguage
        )
    }

    private func persistLocally() {
        defaults.removeObject(forKey: StorageKey.legacyAppLanguage)
        defaults.set(learningContentLanguage.rawValue, forKey: StorageKey.learningLanguage)
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

    private static func languageFromDefaults(_ defaults: UserDefaults) -> AppLanguage {
        if let language = AppLanguage(rawValue: defaults.string(forKey: StorageKey.learningLanguage) ?? "") {
            return language
        }

        if let legacyLanguage = AppLanguage(rawValue: defaults.string(forKey: StorageKey.legacyAppLanguage) ?? "") {
            return legacyLanguage
        }

        return .default
    }
}
