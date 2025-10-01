//
//  RemoteChatConversationDataSourceInterface.swift
//  OurPet
//
//  Created by 전희재 on 9/24/25.
//

import Foundation

protocol RemoteChatConversationDataSourceInterface {
    func fetchConversations(for petId: UUID) async throws -> [ChatConversation]
    func fetchConversation(by id: UUID) async throws -> ChatConversation?
    func upsertConversation(_ conversation: ChatConversation) async throws
    func deleteConversation(id: UUID) async throws
}