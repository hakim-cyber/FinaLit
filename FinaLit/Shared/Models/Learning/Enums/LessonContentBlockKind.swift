//
//  LessonContentBlockKind.swift
//  FinaLit
//

import Foundation

enum LessonContentBlockKind: String, Codable, CaseIterable, Identifiable {
    case paragraph = "paragraph"
    case heading = "heading"
    case section = "section"
    case bulletList = "bulletList"
    case numberedList = "numberedList"
    case quote = "quote"
    case callout = "callout"
    case caseStudy = "caseStudy"
    case action = "action"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paragraph: return "Paragraph"
        case .heading: return "Heading"
        case .section: return "Section"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .quote: return "Quote"
        case .callout: return "Callout"
        case .caseStudy: return "Case Study"
        case .action: return "Action"
        }
    }

    var usesItems: Bool {
        switch self {
        case .bulletList, .numberedList:
            return true
        default:
            return false
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

        switch normalized {
        case "paragraph":
            self = .paragraph
        case "heading":
            self = .heading
        case "section":
            self = .section
        case "bulletlist", "bullet_list", "bullets":
            self = .bulletList
        case "numberedlist", "numbered_list", "numbered":
            self = .numberedList
        case "quote":
            self = .quote
        case "callout":
            self = .callout
        case "casestudy", "case_study", "case":
            self = .caseStudy
        case "action":
            self = .action
        default:
            self = .paragraph
        }
    }
}
