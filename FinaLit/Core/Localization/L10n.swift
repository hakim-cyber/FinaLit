//
//  L10n.swift
//  FinaLit
//

import Foundation

enum L10n {
    static func tr(_ key: String, language: AppLanguage, _ arguments: CVarArg...) -> String {
        tr(key, language: language, arguments: arguments)
    }

    static func tr(_ key: String, preferences: AppPreferencesStore?, _ arguments: CVarArg...) -> String {
        tr(key, language: preferences?.appLanguage ?? .default, arguments: arguments)
    }

    static func tr(_ key: String, language: AppLanguage, arguments: [CVarArg]) -> String {
        let bundle = localizedBundle(for: language)
        let format = NSLocalizedString(key, bundle: bundle, comment: "")

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: language.locale, arguments: arguments)
    }

    private static func localizedBundle(for language: AppLanguage) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }

        return bundle
    }
}
