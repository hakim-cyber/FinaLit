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
        context: AdvisorContextSnapshot,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<String, Error>

    func generateReply(
        userMessage: String,
        intent: ChatIntent,
        context: AdvisorContextSnapshot,
        history: [ChatTurn]
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
    private let generationConfig: GenerationConfig
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

        generationConfig = GenerationConfig(
            temperature: 0.2,
            topP: 0.9,
            maxOutputTokens: 700,
            responseMIMEType: "text/plain"
        )

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
        context: AdvisorContextSnapshot,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<String, Error> {
        let modelHistory = history.suffix(AIChatRuntimeConfig.historyLimit).map { turn in
            let role = turn.role == .assistant ? "model" : "user"
            return ModelContent(role: role, parts: turn.text)
        }

        let prompt = promptBuilder.userPrompt(
            userMessage: userMessage,
            intent: intent,
            context: context
        )

        let candidateModels = uniqueModels(preferred: preferredModelName, fallbacks: fallbackModelNames)
        let backend = backend
        let generationConfig = generationConfig
        let safetySettings = safetySettings
        let systemInstruction = systemInstruction

        return AsyncThrowingStream { continuation in
            Task {
                var lastError: Error?

                for (index, modelName) in candidateModels.enumerated() {
                    do {
                        let model = FirebaseAI.firebaseAI(backend: backend).generativeModel(
                            modelName: modelName,
                            generationConfig: generationConfig,
                            safetySettings: safetySettings,
                            systemInstruction: systemInstruction
                        )

                        let chat = model.startChat(history: modelHistory)
                        let stream = try chat.sendMessageStream(prompt)

                        var aggregated = ""
                        for try await chunk in stream {
                            guard let chunkText = chunk.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                  !chunkText.isEmpty else {
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
        context: AdvisorContextSnapshot,
        history: [ChatTurn]
    ) async throws -> String {
        var finalText = ""

        for try await partial in streamReply(
            userMessage: userMessage,
            intent: intent,
            context: context,
            history: history
        ) {
            finalText = partial
        }

        let trimmed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIChatServiceError.emptyResponse
        }

        return trimmed
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

        if incoming.count >= existing.count, incoming.hasPrefix(existing) {
            return incoming
        }

        if existing.hasSuffix(incoming) {
            return existing
        }

        return existing + " " + incoming
    }
}
