//
//  ChatConversation.swift
//  OurPet
//
//  Created by 전희재 on 9/24/25.
//

import Foundation

// 대화 세션 - 하나의 상담 세션 (상담 시작~완료까지)
struct ChatConversation: Identifiable, Equatable, Hashable {
    enum Status: String, Codable {
        case inProgress
        case completed
        case closed
    }

    let id: UUID
    let petId: UUID
    let startDate: Date
    var lastUpdated: Date
    var responses: [ChatResponse] // response_id와 요약을 포함한 응답들
    var messages: [ChatMessage] // 사용자/AI 메시지 타임라인
    var fullSummary: String // 대화 전체 최종 요약
    var status: Status

    init(
        id: UUID = UUID(),
        petId: UUID,
        startDate: Date = Date(),
        lastUpdated: Date = Date(),
        responses: [ChatResponse] = [],
        messages: [ChatMessage] = [],
        fullSummary: String = "",
        status: Status = .inProgress
    ) {
        self.id = id
        self.petId = petId
        self.startDate = startDate
        self.lastUpdated = lastUpdated
        self.responses = responses
        self.messages = messages
        self.fullSummary = fullSummary
        self.status = status
    }

    var isCompleted: Bool { status == .completed }
}

// 개별 응답 - OpenAI response_id와 요약 포함
struct ChatResponse: Identifiable, Equatable, Hashable {
    let id: UUID
    let responseId: String
    let summary: String
    let date: Date

    init(
        id: UUID = UUID(),
        responseId: String,
        summary: String,
        date: Date = Date()
    ) {
        self.id = id
        self.responseId = responseId
        self.summary = summary
        self.date = date
    }
}

// MARK: - ChatResponse Codable Implementation
extension ChatResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case id, responseId, summary, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // UUID 파싱
        let idString = try container.decode(String.self, forKey: .id)
        guard let parsedId = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string: \(idString)")
        }
        self.id = parsedId

        // 나머지 필드들
        self.responseId = try container.decode(String.self, forKey: .responseId)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.date = try container.decode(Date.self, forKey: .date)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // UUID를 문자열로 인코딩
        try container.encode(id.uuidString, forKey: .id)

        // 나머지 필드들
        try container.encode(responseId, forKey: .responseId)
        try container.encode(summary, forKey: .summary)
        try container.encode(date, forKey: .date)
    }
}

// MARK: - ChatConversation Codable Implementation
extension ChatConversation: Codable {
    enum CodingKeys: String, CodingKey {
        case id, petId, startDate, lastUpdated, responses, messages, fullSummary, status, isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // UUID 파싱
        let idString = try container.decode(String.self, forKey: .id)
        guard let parsedId = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string: \(idString)")
        }
        self.id = parsedId

        let petIdString = try container.decode(String.self, forKey: .petId)
        guard let parsedPetId = UUID(uuidString: petIdString) else {
            throw DecodingError.dataCorruptedError(forKey: .petId, in: container, debugDescription: "Invalid UUID string: \(petIdString)")
        }
        self.petId = parsedPetId

        // 나머지 필드들
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.responses = try container.decode([ChatResponse].self, forKey: .responses)
        self.messages = (try? container.decode([ChatMessage].self, forKey: .messages)) ?? []
        self.fullSummary = try container.decode(String.self, forKey: .fullSummary)

        if let decodedStatus = try container.decodeIfPresent(Status.self, forKey: .status) {
            self.status = decodedStatus
        } else {
            let completed = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
            self.status = completed ? .completed : .inProgress
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // UUID를 문자열로 인코딩
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(petId.uuidString, forKey: .petId)

        // 나머지 필드들
        try container.encode(startDate, forKey: .startDate)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(responses, forKey: .responses)
        try container.encode(messages, forKey: .messages)
        try container.encode(fullSummary, forKey: .fullSummary)
        try container.encode(status, forKey: .status)
        try container.encode(status == .completed, forKey: .isCompleted)
    }
}

extension ChatConversation {
    var latestResponseId: String? {
        responses.sorted { $0.date > $1.date }.first?.responseId
    }

    var responseCount: Int {
        responses.count
    }

    mutating func addResponse(_ response: ChatResponse) {
        responses.append(response)
        lastUpdated = Date()
    }

    mutating func updateMessages(_ messages: [ChatMessage]) {
        // 최신 순서를 유지하도록 정렬 후 저장
        self.messages = messages.sorted { $0.timestamp < $1.timestamp }
        if let latest = self.messages.last?.timestamp {
            lastUpdated = latest
        } else {
            lastUpdated = Date()
        }
    }

    mutating func updateFullSummary(_ summary: String) {
        fullSummary = summary
        lastUpdated = Date()
    }

    mutating func updateStatus(_ status: Status) {
        self.status = status
        lastUpdated = Date()
    }

    mutating func markCompleted() {
        updateStatus(.completed)
    }

    mutating func reopen() {
        updateStatus(.inProgress)
    }

    mutating func close() {
        updateStatus(.closed)
    }
}
