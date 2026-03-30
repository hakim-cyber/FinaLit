//
//  Lesson.swift
//  FinaLit
//

import Foundation
import FirebaseFirestore

struct LessonContentBlock: Codable, Identifiable {
    var id: String = UUID().uuidString
    var kind: LessonContentBlockKind = .paragraph
    var title: String = ""
    var text: String = ""
    var items: [String] = []

    var hasVisibleContent: Bool {
        !title.cleanedText.isEmpty || !text.cleanedText.isEmpty || !normalizedItems.isEmpty
    }

    var normalizedItems: [String] {
        items
            .map(\.cleanedText)
            .filter { !$0.isEmpty }
    }
}

struct Lesson: Codable, Identifiable {
    @DocumentID var id: String?
    var weekNumber: Int = 0
    var dayNumber: Int = 0
    var category: String = ""
    var title: String = ""
    var difficultyLevel: String = DifficultyLevel.beginner.rawValue
    var contentMode: LessonContentMode = .article
    var body: String = ""
    var blocks: [LessonContentBlock] = []

    var cleanedBody: String {
        body.cleanedText
    }

    var normalizedBlocks: [LessonContentBlock] {
        blocks
            .map { block in
                LessonContentBlock(
                    id: block.id.cleanedText.isEmpty ? UUID().uuidString : block.id.cleanedText,
                    kind: block.kind,
                    title: block.title.cleanedText,
                    text: block.text.cleanedText,
                    items: block.normalizedItems
                )
            }
            .filter(\.hasVisibleContent)
    }

    var effectiveContentMode: LessonContentMode {
        let hasBody = !cleanedBody.isEmpty
        let hasBlocks = !normalizedBlocks.isEmpty

        switch contentMode {
        case .auto:
            if hasBody && hasBlocks { return .hybrid }
            if hasBlocks { return .sectioned }
            return .auto
        case .article:
            return hasBody ? .article : (hasBlocks ? .sectioned : .article)
        case .sectioned:
            return hasBlocks ? .sectioned : (hasBody ? .sectioned : .article)
        case .hybrid:
            if hasBody && hasBlocks { return .hybrid }
            if hasBlocks { return .sectioned }
            return .article
        }
    }
}

private extension String {
    var cleanedText: String {
        replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
