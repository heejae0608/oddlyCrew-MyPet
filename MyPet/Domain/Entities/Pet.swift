//
//  Pet.swift
//  MyPet
//
//  Created by 전희재 on 9/17/25.
//

import Foundation

struct ConversationSummary: Identifiable, Codable, Equatable {
    let id: UUID
    let responseId: String
    let summary: String
    let date: Date

    init(responseId: String, summary: String, date: Date = Date()) {
        self.id = UUID()
        self.responseId = responseId
        self.summary = summary
        self.date = date
    }
}

struct Pet: Identifiable, Codable, Equatable {
    var id: UUID
    var userId: UUID
    var name: String
    var species: String
    var breed: String?
    var age: Int
    var gender: String
    var isNeutered: Bool
    var weight: Double?
    var profileImageName: String?
    var existingConditions: String?
    var threadId: String? // Deprecated: Assistants API용
    var responseId: String? // Deprecated: 이제 currentConversationId 사용
    var currentConversationId: UUID? // 현재 활성 대화 세션 ID
    var registrationDate: Date
    var medicalHistory: [MedicalRecord]

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        species: String,
        breed: String? = nil,
        age: Int,
        gender: String,
        isNeutered: Bool,
        weight: Double? = nil,
        profileImageName: String? = nil,
        existingConditions: String? = nil,
        threadId: String? = nil,
        responseId: String? = nil,
        currentConversationId: UUID? = nil,
        registrationDate: Date = Date(),
        medicalHistory: [MedicalRecord] = []
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.gender = gender
        self.isNeutered = isNeutered
        self.weight = weight
        self.profileImageName = profileImageName
        self.existingConditions = existingConditions
        self.threadId = threadId
        self.responseId = responseId
        self.currentConversationId = currentConversationId
        self.registrationDate = registrationDate
        self.medicalHistory = medicalHistory
    }
}

struct MedicalRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var title: String
    var description: String
    var veterinarianName: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        description: String,
        veterinarianName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.veterinarianName = veterinarianName
    }
}

extension Pet {
    static let sampleDog = Pet(
        userId: UUID(),
        name: "초코",
        species: "강아지",
        breed: "포메라니안",
        age: 3,
        gender: "수컷",
        isNeutered: true,
        weight: 4.2
    )
}
