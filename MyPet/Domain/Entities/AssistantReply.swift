//
//  AssistantReply.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

enum UrgencyLevel: String, Codable {
    case low
    case medium
    case high
    case critical
    case unknown
}

enum ConversationStatus: String, Codable {
    case gatheringInfo = "gathering_info"
    case providingAnswer = "providing_answer"
    case unknown
}

struct ChecklistItem: Codable, Equatable {
    let item: String
    let importance: String
}

struct NextStep: Codable, Equatable {
    let step: String
    let importance: String
}

struct AssistantReply: Codable, Equatable {
    let message: String
    let conversationSummary: String?
    let status: ConversationStatus
    let questions: [String]
    let checklist: [ChecklistItem]
    let urgencyLevel: UrgencyLevel
    let vetConsultationNeeded: Bool
    let vetConsultationReason: String?
    let nextSteps: [NextStep]
}

extension AssistantReply {
    static let fallback = AssistantReply(
        message: "응답을 해석할 수 없었어요. 다시 시도해 주세요.",
        conversationSummary: nil,
        status: .unknown,
        questions: [],
        checklist: [],
        urgencyLevel: .unknown,
        vetConsultationNeeded: false,
        vetConsultationReason: nil,
        nextSteps: []
    )
}
