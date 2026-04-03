//
//  LessonContentMode.swift
//  FinaLit
//

import Foundation

enum LessonContentMode: String, Codable, CaseIterable, Identifiable {
    case auto = "auto"
    case article = "article"
    case sectioned = "sectioned"
    case hybrid = "hybrid"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: return "Auto"
        case .article: return "Article"
        case .sectioned: return "Sectioned"
        case .hybrid: return "Hybrid"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        self = Self(rawExternalValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    init(rawExternalValue: String) {
        let normalized = rawExternalValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        self = Self(rawValue: normalized) ?? .auto
    }
}
