//
//  ChatConversationMemoryService.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct ChatConversationMemoryService {
    private let maxMemoryLength = 360
    private let maxPromptLength = 220
    private let maxMemoryItems = 2
    private let contextBuilder = ChatAdvisorContextBuilder()

    func memoryForPrompt(_ memory: String?) -> String? {
        guard let memory else { return nil }
        let cleaned = compactWhitespace(memory)
        guard !cleaned.isEmpty else { return nil }
        return truncate(cleaned, to: maxPromptLength)
    }

    func updatedMemory(existing: String?, userMessage: String, assistantReply: String) -> String {
        guard shouldStoreTurn(userMessage: userMessage) else {
            return existing ?? ""
        }

        let currentTopic = truncate(compactWhitespace(userMessage), to: 90)
        let currentAdvice = truncate(firstSentence(from: assistantReply), to: 120)
        var items = parseItems(from: existing)

        var nextItemParts: [String] = []
        if !currentTopic.isEmpty {
            nextItemParts.append("Topic: \(currentTopic)")
        }
        if !currentAdvice.isEmpty {
            nextItemParts.append("Advice: \(currentAdvice)")
        }

        let nextItem = compactWhitespace(nextItemParts.joined(separator: " | "))
        if !nextItem.isEmpty {
            items.append(nextItem)
        }

        if items.count > maxMemoryItems {
            items = Array(items.suffix(maxMemoryItems))
        }

        if items.isEmpty {
            return ""
        }

        let merged = compactWhitespace(items.joined(separator: " || "))
        return truncate(merged, to: maxMemoryLength)
    }

    private func shouldStoreTurn(userMessage: String) -> Bool {
        contextBuilder.requiresRemoteReply(for: userMessage)
    }

    private func parseItems(from memory: String?) -> [String] {
        guard let memory else { return [] }
        let cleaned = compactWhitespace(memory)
        guard !cleaned.isEmpty else { return [] }

        if cleaned.contains("||") {
            return cleaned
                .components(separatedBy: "||")
                .map(cleanLegacyPrefixes)
                .filter { !$0.isEmpty }
        }

        return [cleanLegacyPrefixes(cleaned)].filter { !$0.isEmpty }
    }

    private func cleanLegacyPrefixes(_ text: String) -> String {
        let withoutPrefix = text.replacingOccurrences(
            of: #"Previous:\s*"#,
            with: "",
            options: .regularExpression
        )
        return compactWhitespace(withoutPrefix)
    }

    private func compactWhitespace(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstSentence(from text: String) -> String {
        let cleaned = compactWhitespace(text)
        guard !cleaned.isEmpty else { return "" }

        if let range = cleaned.range(of: #"[.!?]"#, options: .regularExpression) {
            return String(cleaned[...range.lowerBound])
        }

        return cleaned
    }

    private func truncate(_ value: String, to maxLength: Int) -> String {
        guard value.count > maxLength else { return value }
        let end = value.index(value.startIndex, offsetBy: maxLength)
        return String(value[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
