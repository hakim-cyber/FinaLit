//
//  AppLanguage.swift
//  FinaLit
//

import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Hashable {
    case en
    case az
    case ru

    static let `default`: AppLanguage = .az

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .en:
            return "en"
        case .az:
            return "az_AZ"
        case .ru:
            return "ru_RU"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var displayName: String {
        switch self {
        case .en:
            return "English"
        case .az:
            return "Azerbaijani"
        case .ru:
            return "Russian"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .en:
            return "English"
        case .az:
            return "Azərbaycanca"
        case .ru:
            return "Русский"
        }
    }

    static func from(localeIdentifier: String) -> AppLanguage? {
        let normalized = localeIdentifier.lowercased()

        if normalized.hasPrefix("az") {
            return .az
        }

        if normalized.hasPrefix("ru") {
            return .ru
        }

        if normalized.hasPrefix("en") {
            return .en
        }

        return nil
    }

    static func detectPreferredMessageLanguage(from text: String) -> AppLanguage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if containsCyrillic(trimmed) {
            return .ru
        }

        if containsAzerbaijaniCharacters(trimmed) || containsAzerbaijaniKeywords(trimmed) {
            return .az
        }

        if containsLikelyEnglishKeywords(trimmed) {
            return .en
        }

        return nil
    }

    private static func containsCyrillic(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0400...0x04FF).contains(scalar.value)
        }
    }

    private static func containsAzerbaijaniCharacters(_ text: String) -> Bool {
        let lowercase = text.lowercased()
        let markers = ["ə", "ğ", "ı", "ö", "ş", "ü", "ç"]
        return markers.contains { lowercase.contains($0) }
    }

    private static func containsAzerbaijaniKeywords(_ text: String) -> Bool {
        let normalized = normalize(text)
        let keywords = [
            "salam", "tesekkur", "təşəkkür", "zehmet", "zəhmət",
            "borc", "qenaet", "qənaət", "budce", "büdcə", "gelir",
            "xerc", "xərc", "pul", "investisiya", "necesen", "necəsən"
        ]
        return keywords.contains { normalized.contains($0) }
    }

    private static func containsLikelyEnglishKeywords(_ text: String) -> Bool {
        let normalized = normalize(text)
        let keywords = [
            "hello", "thanks", "budget", "money", "spending",
            "savings", "debt", "invest", "buy", "afford", "income"
        ]
        return keywords.contains { normalized.contains($0) }
    }

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

enum LearningLanguagePreference: Hashable, Identifiable {
    case followApp
    case specific(AppLanguage)

    var id: String {
        switch self {
        case .followApp:
            return "followApp"
        case .specific(let language):
            return language.rawValue
        }
    }
}
