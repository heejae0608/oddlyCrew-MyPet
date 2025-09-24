//
//  Conversation.swift
//  MyPet
//
//  Created by 전희재 on 9/23/25.
//

import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    let petId: UUID
    let responseId: String
    let summary: String
    let date: Date

    init(
        id: UUID = UUID(),
        petId: UUID,
        responseId: String,
        summary: String,
        date: Date = Date()
    ) {
        self.id = id
        self.petId = petId
        self.responseId = responseId
        self.summary = summary
        self.date = date
    }
}

extension Conversation {
    // ConversationSummary와의 호환성을 위한 computed property
    var conversationSummary: ConversationSummary {
        ConversationSummary(responseId: responseId, summary: summary, date: date)
    }
}