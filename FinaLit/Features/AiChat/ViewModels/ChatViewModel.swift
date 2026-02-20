//
//  ChatViewModel.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import Observation
import SwiftData

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
    private let aiService: any AIChatService

    private var thread: ChatThreadEntity?
    private let historyLimit = AIChatRuntimeConfig.historyLimit

    init(
        session: UserSession,
        repository: LocalChatRepository = LocalChatRepository(),
        contextBuilder: ChatAdvisorContextBuilder = ChatAdvisorContextBuilder(),
        aiService: any AIChatService = GeminiAIChatService()
    ) {
        self.session = session
        self.repository = repository
        self.contextBuilder = contextBuilder
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

    func sendMessage(context: ModelContext) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        do {
            guard let uid = session.user?.id else {
                throw ChatViewModelError.userMissing
            }

            if thread?.ownerUID != uid {
                bootstrapIfNeeded(context: context)
            }
            guard let thread else { return }

            errorMessage = nil

            let priorHistory = messages.suffix(historyLimit).map {
                ChatTurn(role: $0.role, text: $0.text)
            }

            draft = ""
            try repository.appendMessage(role: .user, text: text, thread: thread, context: context)
            try refreshMessages(context: context)

            guard let user = session.user else {
                throw ChatViewModelError.userMissing
            }

            isSending = true
            liveAssistantText = nil

            let intent = contextBuilder.classifyIntent(for: text)
            let snapshot = contextBuilder.buildSnapshot(user: user, message: text, intent: intent)

            var finalReply = ""
            for try await partial in aiService.streamReply(
                userMessage: text,
                intent: intent,
                context: snapshot,
                history: priorHistory
            ) {
                liveAssistantText = partial
                finalReply = partial
            }

            let reply = finalReply.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reply.isEmpty else {
                throw AIChatServiceError.emptyResponse
            }

            liveAssistantText = nil
            try repository.appendMessage(role: .assistant, text: reply, thread: thread, context: context)
            try refreshMessages(context: context)
            isSending = false
        } catch {
            isSending = false
            liveAssistantText = nil
            errorMessage = userFacingErrorMessage(for: error)

            do {
                if let thread {
                    let fallbackMessage = assistantFallbackMessage(for: error)

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

    private func userFacingErrorMessage(for error: Error) -> String {
        let lowered = error.localizedDescription.lowercased()

        if lowered.contains("no network route") ||
            lowered.contains("offline") ||
            lowered.contains("not connected") ||
            lowered.contains("network") {
            return "No internet connection. Check your network and try again."
        }

        if lowered.contains("authentication failed") ||
            lowered.contains("api key") ||
            lowered.contains("forbidden") ||
            lowered.contains("unauthenticated") {
            return "AI authentication failed. Verify Firebase AI Logic is enabled and API key restrictions allow AI requests."
        }

        return error.localizedDescription
    }

    private func assistantFallbackMessage(for error: Error) -> String {
        let lowered = error.localizedDescription.lowercased()

        if lowered.contains("no network route") ||
            lowered.contains("offline") ||
            lowered.contains("not connected") ||
            lowered.contains("network") {
            return "I couldn't reach the AI service because your device appears offline. Please reconnect and try again.\nEducational guidance, not financial advice."
        }

        return "I hit an issue while generating a reply. Please try again.\nEducational guidance, not financial advice."
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
