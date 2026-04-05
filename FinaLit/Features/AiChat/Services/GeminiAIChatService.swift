//
//  GeminiAIChatService.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import FirebaseAI

protocol AIChatService {
    func streamReply(
        userMessage: String,
        intent: ChatIntent,
        replyMode: ChatReplyMode,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
    ) -> AsyncThrowingStream<String, Error>

    func generateReply(
        userMessage: String,
        intent: ChatIntent,
        replyMode: ChatReplyMode,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
    ) async throws -> String
}

enum AIChatServiceError: LocalizedError {
    case emptyResponse
    case noReachableModel

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The AI returned an empty response."
        case .noReachableModel:
            return "Unable to reach the selected AI models. Check your AI Logic setup and model availability."
        }
    }
}

final class GeminiAIChatService: AIChatService {
    private let promptBuilder: ChatPromptBuilder
    private let backend: Backend
    private let preferredModelName: String
    private let fallbackModelNames: [String]
    private let safetySettings: [SafetySetting]
    private let systemInstruction: ModelContent

    init(
        modelName: String = AIChatRuntimeConfig.modelName,
        fallbackModelNames: [String] = AIChatRuntimeConfig.fallbackModelNames,
        backend: Backend = AIChatRuntimeConfig.backend,
        promptBuilder: ChatPromptBuilder = ChatPromptBuilder()
    ) {
        self.promptBuilder = promptBuilder
        self.backend = backend
        preferredModelName = modelName
        self.fallbackModelNames = fallbackModelNames

        safetySettings = [
            SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockOnlyHigh),
        ]

        systemInstruction = ModelContent(role: "system", parts: promptBuilder.systemInstruction())
    }

    func streamReply(
        userMessage: String,
        intent: ChatIntent,
        replyMode: ChatReplyMode,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
    ) -> AsyncThrowingStream<String, Error> {
        let prompt = promptBuilder.userPrompt(
            userMessage: userMessage,
            intent: intent,
            replyMode: replyMode,
            context: context,
            conversationMemory: conversationMemory
        )

        let candidateModels = uniqueModels(preferred: preferredModelName, fallbacks: fallbackModelNames)
        let backend = backend
        let generationConfig = generationConfig(for: replyMode)
        let safetySettings = safetySettings
        let systemInstruction = systemInstruction

        return AsyncThrowingStream { continuation in
            Task {
                var lastError: Error?

                for (index, modelName) in candidateModels.enumerated() {
                    var aggregated = ""
                    do {
                        let model = FirebaseAI.firebaseAI(backend: backend).generativeModel(
                            modelName: modelName,
                            generationConfig: generationConfig,
                            safetySettings: safetySettings,
                            systemInstruction: systemInstruction
                        )

                        let chat = model.startChat()
                        let stream = try chat.sendMessageStream(prompt)

                        for try await chunk in stream {
                            guard let chunkText = chunk.text,
                                  !chunkText.isEmpty,
                                  !chunkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                continue
                            }

                            aggregated = mergeStreamChunk(existing: aggregated, incoming: chunkText)
                            continuation.yield(aggregated)
                        }

                        let final = aggregated.trimmingCharacters(in: .whitespacesAndNewlines)
                        if final.isEmpty {
                            throw AIChatServiceError.emptyResponse
                        }

                        continuation.finish()
                        return
                    } catch {
                        // If the model stopped at token limit but produced usable text,
                        // treat that as a successful partial response.
                        if isMaxTokensStop(error),
                           !aggregated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            continuation.yield(aggregated)
                            continuation.finish()
                            return
                        }

                        lastError = error
                        if shouldRetryWithAnotherModel(error: error),
                           index < candidateModels.count - 1 {
                            continue
                        }

                        continuation.finish(throwing: mappedError(error))
                        return
                    }
                }

                continuation.finish(throwing: mappedError(lastError ?? AIChatServiceError.noReachableModel))
            }
        }
    }

    func generateReply(
        userMessage: String,
        intent: ChatIntent,
        replyMode: ChatReplyMode,
        context: AdvisorContextSnapshot,
        conversationMemory: String?
    ) async throws -> String {
        var finalText = ""

        for try await partial in streamReply(
            userMessage: userMessage,
            intent: intent,
            replyMode: replyMode,
            context: context,
            conversationMemory: conversationMemory
        ) {
            finalText = partial
        }

        let trimmed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIChatServiceError.emptyResponse
        }

        return trimmed
    }

    private func generationConfig(for replyMode: ChatReplyMode) -> GenerationConfig {
        switch replyMode {
        case .social:
            return GenerationConfig(
                temperature: 0.15,
                topP: 0.8,
                maxOutputTokens: AIChatRuntimeConfig.maxOutputTokens,
                responseMIMEType: "text/plain"
            )
        case .concise:
            return GenerationConfig(
                temperature: 0.25,
                topP: 0.85,
                maxOutputTokens: AIChatRuntimeConfig.maxOutputTokens,
                responseMIMEType: "text/plain"
            )
        case .deepDive:
            return GenerationConfig(
                temperature: 0.35,
                topP: 0.9,
                maxOutputTokens: AIChatRuntimeConfig.maxOutputTokens,
                responseMIMEType: "text/plain"
            )
        }
    }

    private func uniqueModels(preferred: String, fallbacks: [String]) -> [String] {
        var seen = Set<String>()
        let all = [preferred] + fallbacks
        return all.filter { seen.insert($0).inserted }
    }

    private func shouldRetryWithAnotherModel(error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("unsupported") ||
            message.contains("unknown model") ||
            message.contains("model not found") ||
            message.contains("not found") ||
            message.contains("404")
    }

    private func isMaxTokensStop(_ error: Error) -> Bool {
        if let generateError = error as? GenerateContentError,
           case let .responseStoppedEarly(reason, _) = generateError {
            return reason.rawValue == "MAX_TOKENS"
        }

        return false
    }

    private func mappedError(_ error: Error) -> Error {
        let message = error.localizedDescription.lowercased()

        if message.contains("permission") ||
            message.contains("api key") ||
            message.contains("unauthenticated") ||
            message.contains("forbidden") {
            return NSError(
                domain: "FinaLit.AI",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "AI service authentication failed. Check Firebase AI Logic setup and API key restrictions."
                ]
            )
        }

        return error
    }

    private func mergeStreamChunk(existing: String, incoming: String) -> String {
        if existing.isEmpty {
            return incoming
        }

        // Some providers emit cumulative text snapshots; replace existing in that case.
        if incoming.count >= existing.count, incoming.hasPrefix(existing) {
            return incoming
        }

        // Ignore stale smaller snapshots.
        if existing.hasPrefix(incoming) {
            return existing
        }

        // Merge overlapping incremental chunks to avoid duplicated or glued words.
        let overlapLength = longestOverlapLength(
            suffixOf: existing,
            prefixOf: incoming
        )

        if overlapLength > 0 {
            let start = incoming.index(incoming.startIndex, offsetBy: overlapLength)
            return existing + String(incoming[start...])
        }

        if shouldInsertSpace(between: existing, and: incoming) {
            return existing + " " + incoming
        }

        return existing + incoming
    }

    private func longestOverlapLength(suffixOf existing: String, prefixOf incoming: String) -> Int {
        let maxLength = min(existing.count, incoming.count)
        guard maxLength > 0 else { return 0 }

        for length in stride(from: maxLength, through: 1, by: -1) {
            let existingStart = existing.index(existing.endIndex, offsetBy: -length)
            let incomingEnd = incoming.index(incoming.startIndex, offsetBy: length)

            if existing[existingStart...] == incoming[..<incomingEnd] {
                return length
            }
        }

        return 0
    }

    private func shouldInsertSpace(between existing: String, and incoming: String) -> Bool {
        guard let last = existing.last, let first = incoming.first else { return false }
        guard last.isLetter || last.isNumber else { return false }
        guard first.isLetter || first.isNumber else { return false }
        return true
    }
}
