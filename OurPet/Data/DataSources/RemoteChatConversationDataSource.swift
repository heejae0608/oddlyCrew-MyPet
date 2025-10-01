//
//  RemoteChatConversationDataSource.swift
//  OurPet
//
//  Created by 전희재 on 9/24/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

final class RemoteChatConversationDataSource: RemoteChatConversationDataSourceInterface {
    private let collectionName = "chatConversations"
    private let database: Firestore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        database: Firestore? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        self.database = database ?? Firestore.firestore()
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchConversations(for petId: UUID) async throws -> [ChatConversation] {
        Log.debug("대화 세션 목록 조회 시작 (petId: \(petId.uuidString))", tag: "RemoteChatConversationDataSource")

        let query = database.collection(collectionName)
            .whereField("petId", isEqualTo: petId.uuidString)

        let snapshot = try await query.getDocuments()
        let conversations = try snapshot.documents.compactMap { document in
            try document.data(as: ChatConversation.self)
        }.sorted { $0.lastUpdated > $1.lastUpdated }

        Log.debug("대화 세션 목록 조회 완료 (개수: \(conversations.count))", tag: "RemoteChatConversationDataSource")
        return conversations
    }

    func fetchConversation(by id: UUID) async throws -> ChatConversation? {
        Log.debug("대화 세션 조회 시작 (id: \(id.uuidString))", tag: "RemoteChatConversationDataSource")

        let document = database.collection(collectionName).document(id.uuidString)
        let snapshot = try await document.getDocument()

        let conversation = try snapshot.data(as: ChatConversation?.self)

        Log.debug("대화 세션 조회 완료", tag: "RemoteChatConversationDataSource")
        return conversation
    }

    func upsertConversation(_ conversation: ChatConversation) async throws {
        Log.debug("대화 세션 저장 시작 (id: \(conversation.id.uuidString), responses: \(conversation.responses.count)개)", tag: "RemoteChatConversationDataSource")

        let document = database.collection(collectionName).document(conversation.id.uuidString)
        try document.setData(from: conversation)

        // 저장 후 검증
        let savedDoc = try await document.getDocument()
        if savedDoc.exists {
            Log.debug("✅ 대화 세션 Firestore 저장 완료 및 검증 성공", tag: "RemoteChatConversationDataSource")
        } else {
            Log.error("❌ 대화 세션 Firestore 저장 실패 - 문서가 존재하지 않음", tag: "RemoteChatConversationDataSource")
        }
    }

    func deleteConversation(id: UUID) async throws {
        Log.debug("대화 세션 삭제 시작 (id: \(id.uuidString))", tag: "RemoteChatConversationDataSource")

        let document = database.collection(collectionName).document(id.uuidString)
        try await document.delete()

        Log.debug("대화 세션 삭제 완료", tag: "RemoteChatConversationDataSource")
    }
}