//
//  DailyTip.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct DailyTip: Codable ,Identifiable {
    @DocumentID var id: String?
    var title: String
    var body: String
    var date: Date
    var category: String
    var translations: LocalizedContent<DailyTipTranslationPayload>? = nil

    func resolved(for language: AppLanguage, fallback: AppLanguage = .en) -> DailyTip {
        guard let translation = translations?.value(for: language) ?? translations?.value(for: fallback) else {
            return self
        }

        var copy = self
        let resolvedTitle = translation.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBody = translation.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory = translation.category.trimmingCharacters(in: .whitespacesAndNewlines)

        if !resolvedTitle.isEmpty {
            copy.title = resolvedTitle
        }

        if !resolvedBody.isEmpty {
            copy.body = resolvedBody
        }

        if !resolvedCategory.isEmpty {
            copy.category = resolvedCategory
        }

        return copy
    }
}
