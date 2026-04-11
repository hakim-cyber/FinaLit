//
//  Week.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct Week: Codable,Identifiable {
    @DocumentID var id: String?
    var weekNumber: Int
    var title: String
    var description: String
    var isPublished: Bool
    var translations: LocalizedContent<WeekTranslationPayload>? = nil

    func resolved(for language: AppLanguage, fallback: AppLanguage = .en) -> Week {
        guard let translation = translations?.value(for: language) ?? translations?.value(for: fallback) else {
            return self
        }

        var copy = self
        let resolvedTitle = translation.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedDescription = translation.description.trimmingCharacters(in: .whitespacesAndNewlines)

        if !resolvedTitle.isEmpty {
            copy.title = resolvedTitle
        }

        if !resolvedDescription.isEmpty {
            copy.description = resolvedDescription
        }

        return copy
    }
}
