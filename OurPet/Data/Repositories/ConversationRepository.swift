//
//  ConversationRepository.swift
//  OurPet
//
//  Created by 전희재 on 9/23/25.
//

import Combine
import Foundation

final class ConversationRepository: ConversationRepositoryInterface {
    @Published private var conversations: [Conversation] = []

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        $conversations.eraseToAnyPublisher()
    }

    private let remoteConversationDataSource: RemoteConversationDataSourceInterface

    init(remoteConversationDataSource: RemoteConversationDataSourceInterface) {
        self.remoteConversationDataSource = remoteConversationDataSource
    }

    func getConversations(for petId: UUID) async throws -> [Conversation] {
        Log.debug("대화 목록 조회 시작 (petId: \(petId.uuidString))", tag: "ConversationRepository")

        let conversations = try await remoteConversationDataSource.fetchConversations(for: petId)

        Log.debug("대화 목록 조회 완료 (개수: \(conversations.count))", tag: "ConversationRepository")
        return conversations
    }

    func getConversation(by responseId: String) async throws -> Conversation? {
        Log.debug("대화 조회 시작 (responseId: \(responseId))", tag: "ConversationRepository")

        let conversation = try await remoteConversationDataSource.fetchConversation(by: responseId)

        Log.debug("대화 조회 완료", tag: "ConversationRepository")
        return conversation
    }

    func saveConversation(_ conversation: Conversation) async throws {
        Log.debug("대화 저장 시작 (responseId: \(conversation.responseId))", tag: "ConversationRepository")

        try await remoteConversationDataSource.upsertConversation(conversation)

        // 로컬 캐시 업데이트
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = conversation
            } else {
                conversations.append(conversation)
            }
            conversations.sort { $0.date > $1.date }
        }

        Log.debug("대화 저장 완료", tag: "ConversationRepository")
    }

    func deleteConversation(id: UUID) async throws {
        Log.debug("대화 삭제 시작 (id: \(id.uuidString))", tag: "ConversationRepository")

        try await remoteConversationDataSource.deleteConversation(id: id)

        // 로컬 캐시에서 제거
        await MainActor.run {
            conversations.removeAll { $0.id == id }
        }

        Log.debug("대화 삭제 완료", tag: "ConversationRepository")
    }
}