//
//  RemoteUserDataSource.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

protocol RemoteUserDataSource {
    func fetchUser(uid: String) async throws -> User?
    func upsertUser(_ user: User) async throws
    func deleteUser(uid: String) async throws
}
