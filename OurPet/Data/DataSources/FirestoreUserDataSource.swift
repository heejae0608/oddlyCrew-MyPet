//
//  FirestoreUserDataSource.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import FirebaseCore
import FirebaseFirestore
import Foundation

final class FirestoreUserDataSource: RemoteUserDataSource {
    private let collectionName = "users"
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

    func fetchUser(uid: String) async throws -> User? {
        Log.debug("Firestore fetchUser 시작: \(uid)", tag: "Firestore")
        let documentReference = database.collection(collectionName).document(uid)
        let snapshot = try await documentReference.getDocument()

        guard snapshot.exists, let data = snapshot.data() else {
            Log.info("Firestore 사용자 없음: \(uid)", tag: "Firestore")
            return nil
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        let user = try decoder.decode(User.self, from: jsonData)
        Log.info("Firestore 사용자 로드 성공: \(uid)", tag: "Firestore")
        return user
    }

    func upsertUser(_ user: User) async throws {
        Log.debug("Firestore upsertUser 시작: \(user.appleUserID)", tag: "Firestore")
        let jsonData = try encoder.encode(user)
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "FirestoreUserDataSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user payload"])
        }

        try await database
            .collection(collectionName)
            .document(user.appleUserID)
            .setData(jsonObject, merge: true)
        Log.info("Firestore upsertUser 완료: \(user.appleUserID)", tag: "Firestore")
    }
}
