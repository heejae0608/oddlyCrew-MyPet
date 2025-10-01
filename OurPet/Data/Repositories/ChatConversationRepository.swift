//
//  ChatConversationRepository.swift
//  OurPet
//
//  Created by 전희재 on 9/24/25.
//

import Combine
import Foundation

final class ChatConversationRepository: ChatConversationRepositoryInterface {
    @Published private var conversations: [ChatConversation] = []

    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> {
        $conversations.eraseToAnyPublisher()
    }

    private let remoteDataSource: RemoteChatConversationDataSourceInterface

    init(remoteDataSource: RemoteChatConversationDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    func getConversations(for petId: UUID) async throws -> [ChatConversation] {
        Log.debug("대화 세션 목록 조회 시작 (petId: \(petId.uuidString))", tag: "ChatConversationRepository")

        let conversations = try await remoteDataSource.fetchConversations(for: petId)

        Log.debug("대화 세션 목록 조회 완료 (개수: \(conversations.count))", tag: "ChatConversationRepository")
        return conversations
    }

    func getConversation(by id: UUID) async throws -> ChatConversation? {
        Log.debug("대화 세션 조회 시작 (id: \(id.uuidString))", tag: "ChatConversationRepository")

        let conversation = try await remoteDataSource.fetchConversation(by: id)

        Log.debug("대화 세션 조회 완료", tag: "ChatConversationRepository")
        return conversation
    }

    func saveConversation(_ conversation: ChatConversation) async throws {
        Log.debug("대화 세션 저장 시작 (id: \(conversation.id.uuidString))", tag: "ChatConversationRepository")

        try await remoteDataSource.upsertConversation(conversation)

        // 로컬 캐시 업데이트
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = conversation
            } else {
                conversations.append(conversation)
            }
            conversations.sort { $0.lastUpdated > $1.lastUpdated }
        }

        Log.debug("대화 세션 저장 완료", tag: "ChatConversationRepository")
    }

    func deleteConversation(id: UUID) async throws {
        Log.debug("대화 세션 삭제 시작 (id: \(id.uuidString))", tag: "ChatConversationRepository")

        try await remoteDataSource.deleteConversation(id: id)

        // 로컬 캐시에서 제거
        await MainActor.run {
            conversations.removeAll { $0.id == id }
        }

        Log.debug("대화 세션 삭제 완료", tag: "ChatConversationRepository")
    }

    func addResponse(to conversationId: UUID, response: ChatResponse) async throws {
        Log.debug("응답 추가 시작 (conversationId: \(conversationId.uuidString), responseId: \(response.responseId))", tag: "ChatConversationRepository")

        // 기존 대화 세션 가져오기
        guard var conversation = try await getConversation(by: conversationId) else {
            throw ChatConversationError.conversationNotFound
        }

        // 응답 추가
        conversation.addResponse(response)

        // 저장
        try await saveConversation(conversation)

        Log.debug("응답 추가 완료 - 총 응답 수: \(conversation.responseCount)", tag: "ChatConversationRepository")
    }

    func updateConversationSummary(conversationId: UUID, fullSummary: String) async throws {
        Log.debug("대화 전체 요약 업데이트 시작 (conversationId: \(conversationId.uuidString))", tag: "ChatConversationRepository")
        Log.debug("요약 내용 길이: \(fullSummary.count)자", tag: "ChatConversationRepository")
        Log.debug("요약 내용 미리보기: \(fullSummary.prefix(100))...", tag: "ChatConversationRepository")

        // 기존 대화 세션 가져오기
        guard var conversation = try await getConversation(by: conversationId) else {
            throw ChatConversationError.conversationNotFound
        }

        // 전체 요약 업데이트
        conversation.updateFullSummary(fullSummary)

        // 저장
        try await saveConversation(conversation)

        Log.debug("✅ 대화 전체 요약 업데이트 완료", tag: "ChatConversationRepository")
    }

    func updateConversationMessages(conversationId: UUID, messages: [ChatMessage]) async throws {
        Log.debug("대화 메시지 업데이트 시작 (conversationId: \(conversationId.uuidString), 메시지 수: \(messages.count))", tag: "ChatConversationRepository")

        guard var conversation = try await getConversation(by: conversationId) else {
            throw ChatConversationError.conversationNotFound
        }

        conversation.updateMessages(messages)

        try await saveConversation(conversation)

        Log.debug("✅ 대화 메시지 업데이트 완료", tag: "ChatConversationRepository")
    }

    func markConversationCompleted(conversationId: UUID) async throws {
        Log.debug("상담 완료 처리 시작 (conversationId: \(conversationId.uuidString))", tag: "ChatConversationRepository")

        // 기존 대화 세션 가져오기
        guard var conversation = try await getConversation(by: conversationId) else {
            throw ChatConversationError.conversationNotFound
        }

        // 완료 처리
        conversation.markCompleted()

        // 저장
        try await saveConversation(conversation)

        Log.debug("✅ 상담 완료 처리 완료", tag: "ChatConversationRepository")
    }
}

enum ChatConversationError: Error {
    case conversationNotFound
}
