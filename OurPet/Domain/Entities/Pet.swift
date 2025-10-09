//
//  Pet.swift
//  OurPet
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
    var gender: String
    var isNeutered: Bool    // 중성화 여부
    var weight: Double?
    var profileImageData: String?
    var existingConditions: String?
    var birthDate: Date?
    var adoptionDate: Date?
    var threadId: String? // Deprecated: Assistants API용
    var responseId: String? // Deprecated: 이제 currentConversationId 사용
    var currentConversationId: UUID? // 현재 활성 대화 세션 ID
    var registrationDate: Date
    var medicalHistory: [MedicalRecord]
    private let legacyAge: Int?

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        species: String,
        breed: String? = nil,
        gender: String,
        isNeutered: Bool,
        weight: Double? = nil,
        profileImageData: String? = nil,
        existingConditions: String? = nil,
        birthDate: Date? = nil,
        adoptionDate: Date? = nil,
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
        self.gender = gender
        self.isNeutered = isNeutered
        self.weight = weight
        self.profileImageData = profileImageData
        self.existingConditions = existingConditions
        self.birthDate = birthDate
        self.adoptionDate = adoptionDate
        self.threadId = threadId
        self.responseId = responseId
        self.currentConversationId = currentConversationId
        self.registrationDate = registrationDate
        self.medicalHistory = medicalHistory
        self.legacyAge = nil
    }
}

extension Pet {
    var calculatedAge: Int {
        if let birthDate {
            let now = Date()
            guard birthDate <= now else { return 0 }
            let components = Calendar.current.dateComponents([.year], from: birthDate, to: now)
            return max(0, components.year ?? 0)
        }
        return max(0, legacyAge ?? 0)
    }

    var decodedProfileImageData: Data? {
        guard let profileImageData,
              let data = Data(base64Encoded: profileImageData, options: .ignoreUnknownCharacters) else { return nil }
        return data
    }

}

extension Pet {
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case species
        case breed
        case gender
        case isNeutered
        case weight
        case profileImageData
        case existingConditions
        case birthDate
        case adoptionDate
        case threadId
        case responseId
        case currentConversationId
        case registrationDate
        case medicalHistory
        case legacyAge = "age"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        species = try container.decode(String.self, forKey: .species)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        gender = try container.decode(String.self, forKey: .gender)
        isNeutered = try container.decode(Bool.self, forKey: .isNeutered)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        profileImageData = try container.decodeIfPresent(String.self, forKey: .profileImageData)
        existingConditions = try container.decodeIfPresent(String.self, forKey: .existingConditions)
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        adoptionDate = try container.decodeIfPresent(Date.self, forKey: .adoptionDate)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        responseId = try container.decodeIfPresent(String.self, forKey: .responseId)
        currentConversationId = try container.decodeIfPresent(UUID.self, forKey: .currentConversationId)
        registrationDate = try container.decode(Date.self, forKey: .registrationDate)
        medicalHistory = try container.decodeIfPresent([MedicalRecord].self, forKey: .medicalHistory) ?? []
        legacyAge = try container.decodeIfPresent(Int.self, forKey: .legacyAge)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(species, forKey: .species)
        try container.encodeIfPresent(breed, forKey: .breed)
        try container.encode(gender, forKey: .gender)
        try container.encode(isNeutered, forKey: .isNeutered)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try container.encodeIfPresent(existingConditions, forKey: .existingConditions)
        try container.encodeIfPresent(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(adoptionDate, forKey: .adoptionDate)
        try container.encodeIfPresent(threadId, forKey: .threadId)
        try container.encodeIfPresent(responseId, forKey: .responseId)
        try container.encodeIfPresent(currentConversationId, forKey: .currentConversationId)
        try container.encode(registrationDate, forKey: .registrationDate)
        try container.encode(medicalHistory, forKey: .medicalHistory)
        // legacyAge intentionally not encoded
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
        gender: "수컷",
        isNeutered: true,
        weight: 4.2,
        birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
        adoptionDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())
    )
}
