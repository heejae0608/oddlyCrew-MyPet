//
//  UserDefaultsUserDataSource.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

protocol UserDataSource {
    func loadUser() -> User?
    func save(user: User?) throws
}

enum UserDataSourceError: Error {
    case encodingFailed
}

final class UserDefaultsUserDataSource: UserDataSource {
    private let defaults: UserDefaults
    private let key: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        defaults: UserDefaults = .standard,
        key: String = "current_user",
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.defaults = defaults
        self.key = key
        self.decoder = decoder
        self.encoder = encoder
    }

    func loadUser() -> User? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(User.self, from: data)
    }

    func save(user: User?) throws {
        guard let user else {
            defaults.removeObject(forKey: key)
            return
        }

        guard let data = try? encoder.encode(user) else {
            throw UserDataSourceError.encodingFailed
        }

        defaults.set(data, forKey: key)
    }
}
