//
//  RemoteConversationDataSource.swift
//  OurPet
//
//  Created by 전희재 on 9/23/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

protocol RemoteConversationDataSourceInterface {
    func fetchConversations(for petId: UUID) async throws -> [Conversation]
    func fetchConversation(by responseId: String) async throws -> Conversation?
    func upsertConversation(_ conversation: Conversation) async throws
    func deleteConversation(id: UUID) async throws
}

final class RemoteConversationDataSource: RemoteConversationDataSourceInterface {
    private let collectionName: String
    private let database: Firestore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        database: Firestore? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.collectionName = AppEnvironment.current.collectionName(for: "conversations")
        self.database = database ?? Firestore.firestore()
        self.encoder = encoder
        self.decoder = decoder
    }

    func fetchConversations(for petId: UUID) async throws -> [Conversation] {
        Log.debug("대화 목록 조회 시작 (petId: \(petId.uuidString))", tag: "RemoteConversationDataSource")

        let query = database.collection(collectionName)
            .whereField("petId", isEqualTo: petId.uuidString)
            // .order(by: "date", descending: true) // 임시로 주석 처리

        let snapshot = try await query.getDocuments()
        let conversations = try snapshot.documents.compactMap { document in
            try document.data(as: Conversation.self)
        }.sorted { $0.date > $1.date } // 클라이언트 사이드 정렬

        Log.debug("대화 목록 조회 완료 (개수: \(conversations.count))", tag: "RemoteConversationDataSource")
        return conversations
    }

    func fetchConversation(by responseId: String) async throws -> Conversation? {
        Log.debug("대화 조회 시작 (responseId: \(responseId))", tag: "RemoteConversationDataSource")

        let query = database.collection(collectionName)
            .whereField("responseId", isEqualTo: responseId)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()
        let conversation = try snapshot.documents.first?.data(as: Conversation.self)

        Log.debug("대화 조회 완료", tag: "RemoteConversationDataSource")
        return conversation
    }

    func upsertConversation(_ conversation: Conversation) async throws {
        Log.debug("대화 저장 시작 (id: \(conversation.id.uuidString), responseId: \(conversation.responseId))", tag: "RemoteConversationDataSource")
        Log.debug("저장할 내용 - petId: \(conversation.petId), summary: \(conversation.summary)", tag: "RemoteConversationDataSource")

        let document = database.collection(collectionName).document(conversation.id.uuidString)
        try document.setData(from: conversation)

        // 저장 후 검증
        let savedDoc = try await document.getDocument()
        if savedDoc.exists {
            Log.debug("✅ 대화 Firestore 저장 완료 및 검증 성공", tag: "RemoteConversationDataSource")
        } else {
            Log.error("❌ 대화 Firestore 저장 실패 - 문서가 존재하지 않음", tag: "RemoteConversationDataSource")
        }
    }

    func deleteConversation(id: UUID) async throws {
        Log.debug("대화 삭제 시작 (id: \(id.uuidString))", tag: "RemoteConversationDataSource")

        let document = database.collection(collectionName).document(id.uuidString)
        try await document.delete()

        Log.debug("대화 삭제 완료", tag: "RemoteConversationDataSource")
    }
}
