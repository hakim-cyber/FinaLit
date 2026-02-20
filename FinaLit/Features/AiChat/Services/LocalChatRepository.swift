//
//  LocalChatRepository.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import SwiftData

struct LocalChatRepository {
    func fetchOrCreateDefaultThread(ownerUID: String, context: ModelContext) throws -> ChatThreadEntity {
        var descriptor = FetchDescriptor<ChatThreadEntity>(
            predicate: #Predicate<ChatThreadEntity> { thread in
                thread.ownerUID == ownerUID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let thread = ChatThreadEntity(ownerUID: ownerUID)
        context.insert(thread)
        try context.save()
        return thread
    }

    func fetchMessages(
        threadID: String,
        limit: Int? = nil,
        context: ModelContext
    ) throws -> [ChatMessageEntity] {
        var descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate<ChatMessageEntity> { message in
                message.thread?.id == threadID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        if let limit {
            descriptor.fetchLimit = limit
        }

        return try context.fetch(descriptor)
    }

    @discardableResult
    func appendMessage(
        role: ChatRole,
        text: String,
        thread: ChatThreadEntity,
        context: ModelContext
    ) throws -> ChatMessageEntity {
        let message = ChatMessageEntity(role: role, text: text, thread: thread)
        thread.updatedAt = .now
        context.insert(message)
        try context.save()
        return message
    }

    func clearMessages(thread: ChatThreadEntity, context: ModelContext) throws {
        let messages = try fetchMessages(threadID: thread.id, context: context)
        for message in messages {
            context.delete(message)
        }

        thread.updatedAt = .now
        try context.save()
    }
}
