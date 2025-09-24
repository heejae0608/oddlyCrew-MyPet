//
//  ChatConversationRepositoryInterface.swift
//  MyPet
//
//  Created by 전희재 on 9/24/25.
//

import Combine
import Foundation

protocol ChatConversationRepositoryInterface {
    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> { get }

    func getConversations(for petId: UUID) async throws -> [ChatConversation]
    func getConversation(by id: UUID) async throws -> ChatConversation?
    func saveConversation(_ conversation: ChatConversation) async throws
    func deleteConversation(id: UUID) async throws

    // 응답 추가 (기존 대화 세션에)
    func addResponse(to conversationId: UUID, response: ChatResponse) async throws

    // 대화 전체 요약 업데이트
    func updateConversationSummary(conversationId: UUID, fullSummary: String) async throws

    // 메시지 타임라인 업데이트
    func updateConversationMessages(conversationId: UUID, messages: [ChatMessage]) async throws

    // 상담 완료 처리
    func markConversationCompleted(conversationId: UUID) async throws
}
