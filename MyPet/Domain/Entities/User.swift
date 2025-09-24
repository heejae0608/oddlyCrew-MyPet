//
//  User.swift
//  MyPet
//
//  Created by 전희재 on 9/17/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: UUID
    var appleUserID: String
    var name: String
    var email: String?
    var registrationDate: Date

    init(
        id: UUID = UUID(),
        appleUserID: String,
        name: String,
        email: String? = nil,
        registrationDate: Date = Date()
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.name = name
        self.email = email
        self.registrationDate = registrationDate
    }
}
