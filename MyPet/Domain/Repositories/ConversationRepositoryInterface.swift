//
//  ConversationRepositoryInterface.swift
//  MyPet
//
//  Created by 전희재 on 9/23/25.
//

import Combine
import Foundation

protocol ConversationRepositoryInterface {
    var conversationsPublisher: AnyPublisher<[Conversation], Never> { get }

    func getConversations(for petId: UUID) async throws -> [Conversation]
    func getConversation(by responseId: String) async throws -> Conversation?
    func saveConversation(_ conversation: Conversation) async throws
    func deleteConversation(id: UUID) async throws
}