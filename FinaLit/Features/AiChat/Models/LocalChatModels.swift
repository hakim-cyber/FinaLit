//
//  LocalChatModels.swift
//  FinaLit
//
//  Created by Codex on 2/20/26.
//

import Foundation
import SwiftData

enum ChatRole: String, Codable {
    case user
    case assistant
}

@Model
final class ChatThreadEntity {
    @Attribute(.unique) var id: String
    var ownerUID: String
    var title: String
    var conversationMemory: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChatMessageEntity.thread)
    var messages: [ChatMessageEntity]

    init(
        id: String = UUID().uuidString,
        ownerUID: String,
        title: String = "AI Advisor",
        conversationMemory: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUID = ownerUID
        self.title = title
        self.conversationMemory = conversationMemory
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = []
    }
}

@Model
final class ChatMessageEntity {
    @Attribute(.unique) var id: String
    var roleRawValue: String
    var text: String
    var createdAt: Date
    var thread: ChatThreadEntity?

    init(
        id: String = UUID().uuidString,
        role: ChatRole,
        text: String,
        createdAt: Date = .now,
        thread: ChatThreadEntity? = nil
    ) {
        self.id = id
        self.roleRawValue = role.rawValue
        self.text = text
        self.createdAt = createdAt
        self.thread = thread
    }

    var role: ChatRole {
        get { ChatRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
}
