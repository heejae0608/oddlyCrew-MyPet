//
//  ChatMessage.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

enum ChatMessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var role: ChatMessageRole
    var content: String
    var timestamp: Date
    var petId: UUID?

    init(
        id: UUID = UUID(),
        role: ChatMessageRole,
        content: String,
        timestamp: Date = Date(),
        petId: UUID? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.petId = petId
    }
}

extension ChatMessage {
    static func user(_ content: String, petId: UUID?) -> ChatMessage {
        ChatMessage(role: .user, content: content, petId: petId)
    }

    static func assistant(_ content: String, petId: UUID?) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, petId: petId)
    }
}
