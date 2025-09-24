//
//  RemotePetDataSource.swift
//  MyPet
//
//  Created by 전희재 on 9/23/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

protocol RemotePetDataSourceInterface {
    func fetchPets(for userId: UUID) async throws -> [Pet]
    func fetchPet(id: UUID) async throws -> Pet?
    func upsertPet(_ pet: Pet) async throws
    func deletePet(id: UUID) async throws
}

final class RemotePetDataSource: RemotePetDataSourceInterface {
    private let collectionName = "pets"
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

    func fetchPets(for userId: UUID) async throws -> [Pet] {
        Log.debug("펫 목록 조회 시작 (userId: \(userId.uuidString))", tag: "RemotePetDataSource")

        let query = database.collection(collectionName)
            .whereField("userId", isEqualTo: userId.uuidString)

        let snapshot = try await query.getDocuments()
        let pets = try snapshot.documents.compactMap { document in
            try document.data(as: Pet.self)
        }

        Log.debug("펫 목록 조회 완료 (개수: \(pets.count))", tag: "RemotePetDataSource")
        return pets
    }

    func fetchPet(id: UUID) async throws -> Pet? {
        Log.debug("펫 조회 시작 (id: \(id.uuidString))", tag: "RemotePetDataSource")

        let document = database.collection(collectionName).document(id.uuidString)
        let snapshot = try await document.getDocument()

        guard snapshot.exists else {
            Log.debug("펫을 찾을 수 없음", tag: "RemotePetDataSource")
            return nil
        }

        let pet = try snapshot.data(as: Pet.self)
        Log.debug("펫 조회 완료", tag: "RemotePetDataSource")
        return pet
    }

    func upsertPet(_ pet: Pet) async throws {
        Log.debug("펫 저장 시작 (id: \(pet.id.uuidString), name: \(pet.name))", tag: "RemotePetDataSource")

        let document = database.collection(collectionName).document(pet.id.uuidString)
        try document.setData(from: pet)

        Log.debug("펫 저장 완료", tag: "RemotePetDataSource")
    }

    func deletePet(id: UUID) async throws {
        Log.debug("펫 삭제 시작 (id: \(id.uuidString))", tag: "RemotePetDataSource")

        let document = database.collection(collectionName).document(id.uuidString)
        try await document.delete()

        Log.debug("펫 삭제 완료", tag: "RemotePetDataSource")
    }
}