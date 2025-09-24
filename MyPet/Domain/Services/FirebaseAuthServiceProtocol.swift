//
//  FirebaseAuthServiceProtocol.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

struct FirebaseUserInfo: Equatable {
    let uid: String
    let name: String?
    let email: String?
}

protocol FirebaseAuthServiceProtocol {
    func signInWithApple(idToken: String, nonce: String) async throws -> FirebaseUserInfo
    func signOut() throws
    func currentUser() -> FirebaseUserInfo?
    func fetchIDToken(forceRefresh: Bool) async throws -> String?
}
