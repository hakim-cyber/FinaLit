//
//  ChatViewModel.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import Observation
import SwiftData
import FirebaseAI

@MainActor
@Observable
final class ChatViewModel {
    var draft: String = ""
    var messages: [ChatMessageEntity] = []
    var isLoading: Bool = false
    var isSending: Bool = false
    var liveAssistantText: String?
    var errorMessage: String?

    private let session: UserSession
    private let repository: LocalChatRepository
    private let contextBuilder: ChatAdvisorContextBuilder
    private let memoryService: ChatConversationMemoryService
    private let aiService: any AIChatService

    private var thread: ChatThreadEntity?
    private var financialContext: AIFinancialContext?

    init(
        session: UserSession,
        repository: LocalChatRepository = LocalChatRepository(),
        contextBuilder: ChatAdvisorContextBuilder = ChatAdvisorContextBuilder(),
        memoryService: ChatConversationMemoryService = ChatConversationMemoryService(),
        aiService: any AIChatService = GeminiAIChatService()
    ) {
        self.session = session
        self.repository = repository
        self.contextBuilder = contextBuilder
        self.memoryService = memoryService
        self.aiService = aiService
    }

    func bootstrapIfNeeded(context: ModelContext) {
        guard let uid = session.user?.id else {
            errorMessage = ChatViewModelError.userMissing.errorDescription
            return
        }

        if thread?.ownerUID == uid { return }

        isLoading = true
        errorMessage = nil

        do {
            let thread = try repository.fetchOrCreateDefaultThread(ownerUID: uid, context: context)
            self.thread = thread
            try refreshMessages(context: context)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateFinancialContext(_ context: AIFinancialContext?) {
        financialContext = context
    }

    func sendMessage(context: ModelContext) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        var streamedReply = ""

        do {
            guard let uid = session.user?.id else {
                throw ChatViewModelError.userMissing
            }

            if thread?.ownerUID != uid {
                bootstrapIfNeeded(context: context)
            }
            guard let thread else { return }

            errorMessage = nil

            draft = ""
            try repository.appendMessage(role: .user, text: text, thread: thread, context: context)
            try refreshMessages(context: context)

            guard let user = session.user else {
                throw ChatViewModelError.userMissing
            }

            isSending = true
            liveAssistantText = nil

            let intent = contextBuilder.classifyIntent(for: text)
            let snapshot = contextBuilder.buildSnapshot(
                user: user,
                message: text,
                intent: intent,
                financialContext: financialContext
            )
            let memoryForPrompt = memoryService.memoryForPrompt(thread.conversationMemory)

            var finalReply = ""
            for try await partial in aiService.streamReply(
                userMessage: text,
                intent: intent,
                context: snapshot,
                conversationMemory: memoryForPrompt
            ) {
                liveAssistantText = partial
                finalReply = partial
                streamedReply = partial
            }

            let reply = finalReply.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reply.isEmpty else {
                throw AIChatServiceError.emptyResponse
            }

            liveAssistantText = nil
            try repository.appendMessage(role: .assistant, text: reply, thread: thread, context: context)

            thread.conversationMemory = memoryService.updatedMemory(
                existing: thread.conversationMemory,
                userMessage: text,
                assistantReply: reply
            )
            try context.save()

            try refreshMessages(context: context)
            isSending = false
        } catch {
            if shouldUsePartialReply(after: error),
               !streamedReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let thread {
                do {
                    let partialCore = streamedReply.trimmingCharacters(in: .whitespacesAndNewlines)
                    let truncatedReply = partialCore + "\n\n(Partial response due to model stop condition.)"
                    liveAssistantText = nil
                    try repository.appendMessage(
                        role: .assistant,
                        text: truncatedReply,
                        thread: thread,
                        context: context
                    )

                    thread.conversationMemory = memoryService.updatedMemory(
                        existing: thread.conversationMemory,
                        userMessage: text,
                        assistantReply: partialCore
                    )
                    try context.save()

                    try refreshMessages(context: context)
                    isSending = false
                    errorMessage = partialReplyHint(for: error)
                    return
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            isSending = false
            liveAssistantText = nil
            let diagnosis = diagnoseAIError(error)
            errorMessage = diagnosis.userMessage
#if DEBUG
            print("AI error diagnosis: \(diagnosis.debugDetails)")
#endif

            do {
                if let thread {
                    let fallbackMessage = diagnosis.assistantMessage

                    if messages.last?.role == .assistant && messages.last?.text == fallbackMessage {
                        return
                    }

                    try repository.appendMessage(
                        role: .assistant,
                        text: fallbackMessage,
                        thread: thread,
                        context: context
                    )
                    try refreshMessages(context: context)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearChat(context: ModelContext) {
        guard let thread else { return }

        do {
            try repository.clearMessages(thread: thread, context: context)
            try refreshMessages(context: context)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshMessages(context: ModelContext) throws {
        guard let thread else {
            messages = []
            return
        }

        messages = try repository.fetchMessages(threadID: thread.id, context: context)
    }

    private func shouldUsePartialReply(after error: Error) -> Bool {
        if let generateError = error as? GenerateContentError,
           case let .responseStoppedEarly(reason, _) = generateError {
            return reason.rawValue == "MAX_TOKENS"
        }

        let nsError = error as NSError
        return nsError.domain.contains("GenerateContentError") && nsError.code == 3
    }

    private func partialReplyHint(for error: Error) -> String {
        if let generateError = error as? GenerateContentError,
           case let .responseStoppedEarly(reason, _) = generateError {
            return "AI stopped early (\(reason.rawValue)). Showing partial response."
        }

        return "AI stopped early. Showing partial response."
    }

    private func diagnoseAIError(_ error: Error) -> (userMessage: String, assistantMessage: String, debugDetails: String) {
        if let generateError = error as? GenerateContentError {
            switch generateError {
            case let .promptBlocked(response):
                let blockReason = response.promptFeedback?.blockReason?.rawValue ?? "UNKNOWN"
                let blockMessage = response.promptFeedback?.blockReasonMessage ?? "Prompt was blocked."
                return (
                    "Prompt blocked by model safety (\(blockReason)). Try rephrasing.",
                    "I couldn't answer because the prompt was blocked by safety checks (\(blockReason)). Try rephrasing your question.\nEducational guidance, not financial advice.",
                    "GenerateContentError.promptBlocked reason=\(blockReason) message=\(blockMessage)"
                )

            case let .responseStoppedEarly(reason, _):
                if reason.rawValue == "SAFETY" ||
                    reason.rawValue == "BLOCKLIST" ||
                    reason.rawValue == "PROHIBITED_CONTENT" ||
                    reason.rawValue == "SPII" {
                    return (
                        "Model blocked the response for safety (\(reason.rawValue)). Try rephrasing.",
                        "I couldn't complete this answer because the model stopped for safety (\(reason.rawValue)). Try a safer phrasing.\nEducational guidance, not financial advice.",
                        "GenerateContentError.responseStoppedEarly finishReason=\(reason.rawValue)"
                    )
                }

                if reason.rawValue == "MAX_TOKENS" {
                    return (
                        "AI output limit reached (\(reason.rawValue)). Try asking for a shorter answer.",
                        "I reached the response length limit. Ask for a shorter focused answer or continue from the last point.\nEducational guidance, not financial advice.",
                        "GenerateContentError.responseStoppedEarly finishReason=\(reason.rawValue)"
                    )
                }

                return (
                    "AI stopped early (\(reason.rawValue)). Please try again.",
                    "I couldn't complete the response because generation stopped early (\(reason.rawValue)). Please try again.\nEducational guidance, not financial advice.",
                    "GenerateContentError.responseStoppedEarly finishReason=\(reason.rawValue)"
                )

            case let .promptImageContentError(underlying):
                return (
                    "Invalid prompt content for AI request.",
                    "I couldn't process this request because the prompt content format was invalid.\nEducational guidance, not financial advice.",
                    "GenerateContentError.promptImageContentError underlying=\(underlying)"
                )

            case let .internalError(underlying):
                return diagnoseGenericError(underlying)
            }
        }

        return diagnoseGenericError(error)
    }

    private func diagnoseGenericError(_ error: Error) -> (userMessage: String, assistantMessage: String, debugDetails: String) {
        let lowered = error.localizedDescription.lowercased()
        let nsError = error as NSError

        if lowered.contains("no network route") ||
            lowered.contains("offline") ||
            lowered.contains("not connected") ||
            lowered.contains("network") {
            return (
                "No internet connection. Check your network and try again.",
                "I couldn't reach the AI service because your device appears offline. Please reconnect and try again.\nEducational guidance, not financial advice.",
                "Network error domain=\(nsError.domain) code=\(nsError.code) desc=\(error.localizedDescription)"
            )
        }

        if lowered.contains("authentication failed") ||
            lowered.contains("api key") ||
            lowered.contains("forbidden") ||
            lowered.contains("unauthenticated") ||
            lowered.contains("permission") {
            return (
                "AI authentication failed. Verify Firebase AI Logic setup and API key restrictions.",
                "I couldn't authenticate with the AI service. Please verify project setup and API key restrictions.\nEducational guidance, not financial advice.",
                "Auth error domain=\(nsError.domain) code=\(nsError.code) desc=\(error.localizedDescription)"
            )
        }

        if nsError.domain.contains("GenerateContentError"), nsError.code == 3 {
            return (
                "Model stopped generation early (error 3). This is usually safety or token limit.",
                "The AI stopped generation early. Try a simpler or shorter prompt.\nEducational guidance, not financial advice.",
                "GenerateContentError code=3 desc=\(error.localizedDescription)"
            )
        }

        return (
            error.localizedDescription,
            "I hit an issue while generating a reply. Please try again.\nEducational guidance, not financial advice.",
            "Unhandled error domain=\(nsError.domain) code=\(nsError.code) desc=\(error.localizedDescription)"
        )
    }
}

enum ChatViewModelError: LocalizedError {
    case userMissing

    var errorDescription: String? {
        switch self {
        case .userMissing:
            return "User data is missing. Please log out and log in again."
        }
    }
}
