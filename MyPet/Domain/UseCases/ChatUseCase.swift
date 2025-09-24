//
//  ChatUseCase.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import Foundation

protocol ChatUseCaseInterface {
    func history(for petId: UUID?) -> [ChatMessage]
    func loadLastConversation(for pet: Pet) async -> [ChatMessage]
    func append(_ message: ChatMessage)
    func clearHistory(for petId: UUID?)
    func startNewConversation(for petId: UUID)
    func send(messages: [ChatMessage], pet: Pet?) -> AnyPublisher<AssistantReply, Error>
}

final class ChatUseCase: ChatUseCaseInterface {
    private let userRepository: UserRepositoryInterface
    private let petRepository: PetRepositoryInterface
    private let conversationRepository: ConversationRepositoryInterface
    private let chatConversationRepository: ChatConversationRepositoryInterface
    private let chatService: ChatGPTServicing
    private let maxTurnCount = 6


    init(
        userRepository: UserRepositoryInterface,
        petRepository: PetRepositoryInterface,
        conversationRepository: ConversationRepositoryInterface,
        chatConversationRepository: ChatConversationRepositoryInterface,
        chatService: ChatGPTServicing
    ) {
        self.userRepository = userRepository
        self.petRepository = petRepository
        self.conversationRepository = conversationRepository
        self.chatConversationRepository = chatConversationRepository
        self.chatService = chatService
    }

    func history(for petId: UUID?) -> [ChatMessage] {
        return []
    }

    func loadLastConversation(for pet: Pet) async -> [ChatMessage] {
        Log.debug("전체 대화 이력 불러오기 시작 (petId: \(pet.id))", tag: "ChatUseCase")

        do {
            let conversations = try await chatConversationRepository
                .getConversations(for: pet.id)
                .sorted { $0.startDate < $1.startDate }

            guard conversations.isEmpty == false else {
                Log.debug("저장된 대화 세션 없음", tag: "ChatUseCase")
                let legacy = await loadLegacyConversationIfNeeded(for: pet)
                return limitMessagesToRecentTurns(legacy, limit: maxTurnCount)
            }

            var aggregatedMessages: [ChatMessage] = []
            aggregatedMessages.reserveCapacity(conversations.reduce(0) { $0 + $1.messages.count })

            for conversation in conversations {
                let messages = resolveMessages(from: conversation, petId: pet.id)
                if messages.isEmpty == false {
                    aggregatedMessages.append(contentsOf: messages)
                } else {
                    aggregatedMessages.append(contentsOf: fallbackMessages(from: conversation, petId: pet.id))
                }
            }

            if aggregatedMessages.isEmpty {
                Log.debug("모든 세션에 저장된 메시지가 없어 레거시 데이터 확인", tag: "ChatUseCase")
                let legacy = await loadLegacyConversationIfNeeded(for: pet)
                return limitMessagesToRecentTurns(legacy, limit: maxTurnCount)
            }

            // 최신 활성 세션 동기화
            let activeConversation: ChatConversation? = {
                if let currentId = pet.currentConversationId,
                   let existing = conversations.first(where: { $0.id == currentId }) {
                    return existing
                }
                return conversations.last(where: { $0.isCompleted == false }) ?? conversations.last
            }()

            if let activeConversation,
               activeConversation.isCompleted == false,
               pet.currentConversationId != activeConversation.id {
                var updatedPet = pet
                updatedPet.currentConversationId = activeConversation.id
                try await petRepository.updatePet(updatedPet)
                Log.debug("currentConversationId 갱신 (id: \(activeConversation.id))", tag: "ChatUseCase")
            } else if (activeConversation == nil || activeConversation?.isCompleted == true) && pet.currentConversationId != nil {
                var updatedPet = pet
                updatedPet.currentConversationId = nil
                try await petRepository.updatePet(updatedPet)
                Log.debug("활성 세션 없음 - currentConversationId 초기화", tag: "ChatUseCase")
            }

            let sortedMessages = aggregatedMessages.sorted { $0.timestamp < $1.timestamp }
            let limitedMessages = limitMessagesToRecentTurns(sortedMessages, limit: maxTurnCount)
            Log.info("✅ 전체 대화 이력 로드 완료 (총 메시지 수: \(sortedMessages.count), 반환: \(limitedMessages.count))", tag: "ChatUseCase")
            return limitedMessages
        } catch {
            Log.error("대화 이력 불러오기 실패: \(error.localizedDescription)", tag: "ChatUseCase")
            return []
        }
    }

    func hasActiveConversation(for pet: Pet) async -> Bool {
        guard let conversationId = pet.currentConversationId else {
            return false
        }

        do {
            let conversation = try await chatConversationRepository.getConversation(by: conversationId)
            let hasConversation = conversation != nil && (
                conversation!.responseCount > 0 ||
                conversation!.messages.isEmpty == false
            )

            if hasConversation {
                Log.info("🔄 이전 대화 세션 감지 (응답 수: \(conversation!.responseCount))", tag: "ChatUseCase")
            }

            return hasConversation
        } catch {
            Log.error("대화 세션 확인 실패: \(error.localizedDescription)", tag: "ChatUseCase")
            return false
        }
    }

    func append(_ message: ChatMessage) {
        // 현재 세션용 임시 저장 (앱 재시작 시 초기화)
    }

    func clearHistory(for petId: UUID?) {
        Task {
            do {
                if let petId {
                    if let pet = petRepository.pets.first(where: { $0.id == petId }) {
                        var updatedPet = pet
                        updatedPet.currentConversationId = nil
                        updatedPet.responseId = nil
                        try await petRepository.updatePet(updatedPet)
                        Log.info("대화 세션 초기화 완료 (petId: \(petId.uuidString))", tag: "ChatUseCase")
                    }
                } else {
                    for pet in petRepository.pets {
                        var updatedPet = pet
                        updatedPet.currentConversationId = nil
                        updatedPet.responseId = nil
                        try await petRepository.updatePet(updatedPet)
                    }
                    Log.info("모든 펫 대화 세션 초기화 완료", tag: "ChatUseCase")
                }
            } catch {
                Log.error("대화 세션 초기화 실패: \(error.localizedDescription)", tag: "ChatUseCase")
            }
        }
    }

    func startNewConversation(for petId: UUID) {
        Task {
            do {
                if let pet = petRepository.pets.first(where: { $0.id == petId }) {
                    var updatedPet = pet
                    updatedPet.currentConversationId = nil // 현재 세션 종료
                    try await petRepository.updatePet(updatedPet)
                    Log.info("새로운 대화 시작 준비 완료 (petId: \(petId.uuidString))", tag: "ChatUseCase")
                }
            } catch {
                Log.error("새로운 대화 시작 준비 실패: \(error.localizedDescription)", tag: "ChatUseCase")
            }
        }
    }

    func send(messages: [ChatMessage], pet: Pet?) -> AnyPublisher<AssistantReply, Error> {
        Log.debug("ChatGPT 서비스 호출 (메시지 수: \(messages.count))", tag: "ChatUseCase")

        let resolvedPet: Pet? = {
            guard let pet else { return nil }
            if let storedPet = petRepository.pets.first(where: { $0.id == pet.id }) {
                Log.debug("펫 정보 확인 - currentConversationId: \(storedPet.currentConversationId?.uuidString ?? "nil")", tag: "ChatUseCase")
                return storedPet
            }
            return pet
        }()

        // 새로운 대화 구조 사용
        return Future<(ChatConversation?, String?), Error> { promise in
            Task {
                do {
                    guard let petId = resolvedPet?.id else {
                        promise(.success((nil, nil)))
                        return
                    }

                    var currentConversation: ChatConversation?
                    var previousSummary: String?

                    // 현재 활성 대화 세션 확인
                    if let conversationId = resolvedPet?.currentConversationId {
                        Log.debug("🔍 기존 대화 세션 조회 중 (id: \(conversationId))", tag: "ChatUseCase")
                        currentConversation = try await self.chatConversationRepository.getConversation(by: conversationId)

                        if let conversation = currentConversation {
                            // 완료된 세션이면 새 세션 시작
                            if conversation.isCompleted {
                                Log.debug("✅ 기존 대화 세션이 완료됨 - 새 세션 생성", tag: "ChatUseCase")
                                currentConversation = nil // 새 세션 생성하도록
                            } else {
                                // fullSummary를 previousSummary로 전달 (대화 맥락 유지)
                                if !conversation.fullSummary.isEmpty {
                                    previousSummary = conversation.fullSummary
                                } else if conversation.messages.isEmpty == false {
                                    previousSummary = self.buildTranscriptSummary(from: conversation.messages)
                                } else if let latestResponseId = conversation.latestResponseId {
                                    previousSummary = latestResponseId // fallback으로 response_id 사용
                                }
                                Log.debug("🔄 기존 대화 세션 사용!", tag: "ChatUseCase")
                                Log.debug("  - 세션 ID: \(conversationId)", tag: "ChatUseCase")
                                Log.debug("  - 응답 수: \(conversation.responseCount)", tag: "ChatUseCase")
                                Log.debug("  - 완료 상태: \(conversation.isCompleted)", tag: "ChatUseCase")
                                Log.debug("  - 전체 요약 길이: \(conversation.fullSummary.count)자", tag: "ChatUseCase")
                                Log.debug("  - 전달할 previousSummary: \(previousSummary?.prefix(100) ?? "없음")...", tag: "ChatUseCase")
                            }
                        } else {
                            Log.warning("⚠️ 기존 대화 세션을 찾을 수 없음 (id: \(conversationId)) - 새 세션 생성", tag: "ChatUseCase")
                        }
                    } else {
                        Log.debug("📋 현재 활성 대화 세션 없음 - 새 세션 생성", tag: "ChatUseCase")
                    }

                    // 활성 대화가 없으면 새로 생성
                    if currentConversation == nil {
                        currentConversation = ChatConversation(petId: petId)
                        try await self.chatConversationRepository.saveConversation(currentConversation!)

                        // Pet의 currentConversationId 업데이트
                        var updatedPet = resolvedPet!
                        updatedPet.currentConversationId = currentConversation!.id
                        try await self.petRepository.updatePet(updatedPet)

                        Log.info("🆕 새로운 대화 세션 시작", tag: "ChatUseCase")
                        Log.debug("  - 새 세션 ID: \(currentConversation!.id)", tag: "ChatUseCase")
                        Log.debug("  - 펫 ID: \(petId)", tag: "ChatUseCase")
                    }

                    promise(.success((currentConversation, previousSummary)))
                } catch {
                    Log.error("대화 세션 준비 실패: \(error.localizedDescription)", tag: "ChatUseCase")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
        .flatMap { (conversation, previousSummary) in
            return self.chatService.send(messages: messages, pet: resolvedPet, previousSummary: previousSummary)
                .map { result in (result, conversation) }
        }
            .handleEvents(receiveOutput: { [weak self] (result, conversation) in
                guard let self, let petId = resolvedPet?.id, let conversation else { return }

                Task {
                    do {
                        // OpenAI 응답 처리 및 요약 저장
                        Log.debug("📝 응답 처리 시작", tag: "ChatUseCase")
                        Log.debug("  - responseId: \(result.conversationId ?? "nil")", tag: "ChatUseCase")
                        Log.debug("  - 상담 상태: \(result.reply.status)", tag: "ChatUseCase")
                        Log.debug("  - 요약 존재: \(result.reply.conversationSummary != nil)", tag: "ChatUseCase")

                        let assistantMessage = ChatMessage.assistant(result.reply.message, petId: resolvedPet?.id)

                        if let responseId = result.conversationId,
                           let summary = result.reply.conversationSummary,
                           !summary.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {

                            // ChatResponse 생성
                            let chatResponse = ChatResponse(
                                responseId: responseId,
                                summary: summary,
                                date: Date()
                            )

                            Log.debug("📋 응답 요약 저장", tag: "ChatUseCase")
                            Log.debug("  - response_id: \(responseId)", tag: "ChatUseCase")
                            Log.debug("  - 요약 길이: \(summary.count)자", tag: "ChatUseCase")
                            Log.debug("  - 요약 미리보기: \(summary.prefix(100))...", tag: "ChatUseCase")

                            // 대화 세션에 응답 추가
                            try await self.chatConversationRepository.addResponse(
                                to: conversation.id,
                                response: chatResponse
                            )

                            // 대화 전체 요약 업데이트 (개별 응답들을 누적)
                            let updatedConversation = try await self.chatConversationRepository.getConversation(by: conversation.id)
                            if let conv = updatedConversation {
                                let cumulativeSummary = conv.responses
                                    .sorted { $0.date < $1.date }
                                    .map { $0.summary }
                                    .joined(separator: "\n\n")

                                try await self.chatConversationRepository.updateConversationSummary(
                                    conversationId: conversation.id,
                                    fullSummary: cumulativeSummary
                                )

                                Log.debug("📝 누적 요약 업데이트 완료", tag: "ChatUseCase")
                                Log.debug("  - 총 응답 수: \(conv.responses.count)", tag: "ChatUseCase")
                                Log.debug("  - 누적 요약 길이: \(cumulativeSummary.count)자", tag: "ChatUseCase")
                            }

                            Log.debug("✅ 응답 및 요약 저장 완료", tag: "ChatUseCase")
                        } else {
                            Log.debug("❌ 요약 저장 건너뛰기", tag: "ChatUseCase")
                            Log.debug("  - responseId 있음: \(result.conversationId != nil)", tag: "ChatUseCase")
                            Log.debug("  - summary 내용: '\(result.reply.conversationSummary ?? "nil")'", tag: "ChatUseCase")
                        }

                        // 전체 메시지 로그 저장 (사용자 + AI)
                        let updatedMessages = self.buildUpdatedMessages(from: messages, assistantMessage: assistantMessage)
                        try await self.chatConversationRepository.updateConversationMessages(
                            conversationId: conversation.id,
                            messages: updatedMessages
                        )
                        Log.debug("💾 대화 메시지 로그 저장 완료 (총 \(updatedMessages.count)개)", tag: "ChatUseCase")

                        // 상담 완료 처리 (하지만 세션은 유지)
                        if result.reply.status == .providingAnswer {
                            Log.info("🏁 상담 완료 - 하지만 계속 대화 가능하도록 세션 유지", tag: "ChatUseCase")

                            try await self.chatConversationRepository.markConversationCompleted(
                                conversationId: conversation.id
                            )

                            Log.debug("  - 세션 상태: 완료됨 (계속 대화 가능)", tag: "ChatUseCase")
                            Log.debug("  - currentConversationId: 유지됨", tag: "ChatUseCase")
                        } else {
                            Log.debug("🔄 상담 진행 중 - 세션 유지", tag: "ChatUseCase")
                        }
                    } catch {
                        Log.error("대화 세션 정보 저장 실패: \(error.localizedDescription)", tag: "ChatUseCase")
                    }
                }
            })
            .map { (result, _) in result.reply }
            .eraseToAnyPublisher()
    }



}

// MARK: - Private Helpers

private extension ChatUseCase {
    func resolveMessages(from conversation: ChatConversation, petId: UUID) -> [ChatMessage] {
        if conversation.messages.isEmpty == false {
            return conversation.messages.sorted { $0.timestamp < $1.timestamp }
        }

        if conversation.responses.isEmpty == false {
            return conversation.responses
                .sorted { $0.date < $1.date }
                .map { response in
                    ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response.summary,
                        timestamp: response.date,
                        petId: petId
                    )
                }
        }

        return []
    }

    func fallbackMessages(from conversation: ChatConversation, petId: UUID) -> [ChatMessage] {
        guard conversation.fullSummary.isEmpty == false else { return [] }

        let message = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: conversation.fullSummary,
            timestamp: conversation.lastUpdated,
            petId: petId
        )
        return [message]
    }

    func loadLegacyConversationIfNeeded(for pet: Pet) async -> [ChatMessage] {
        guard let legacyResponseId = pet.responseId else { return [] }
        do {
            if let legacyConversation = try await conversationRepository.getConversation(by: legacyResponseId) {
                Log.info("ℹ️ 레거시 responseId 기반 대화 복원", tag: "ChatUseCase")
                return [
                    ChatMessage(
                        id: legacyConversation.id,
                        role: .assistant,
                        content: legacyConversation.summary,
                        timestamp: legacyConversation.date,
                        petId: pet.id
                    )
                ]
            }
        } catch {
            Log.error("레거시 대화 복원 실패: \(error.localizedDescription)", tag: "ChatUseCase")
        }
        return []
    }

    func buildTranscriptSummary(from messages: [ChatMessage]) -> String {
        let recentMessages = messages.sorted { $0.timestamp < $1.timestamp }.suffix(10)
        return recentMessages.map { message in
            let role: String
            switch message.role {
            case .user:
                role = "사용자"
            case .assistant:
                role = "AI"
            case .system:
                role = "시스템"
            }
            return "\(role): \(message.content)"
        }.joined(separator: "\n")
    }

    func buildUpdatedMessages(from currentMessages: [ChatMessage], assistantMessage: ChatMessage) -> [ChatMessage] {
        var timeline = currentMessages
        timeline.append(assistantMessage)
        return timeline.sorted { $0.timestamp < $1.timestamp }
    }

    func limitMessagesToRecentTurns(_ messages: [ChatMessage], limit: Int) -> [ChatMessage] {
        guard limit > 0 else { return [] }
        guard messages.isEmpty == false else { return [] }

        var turns: [[ChatMessage]] = []
        var currentTurn: [ChatMessage] = []

        for message in messages {
            switch message.role {
            case .user:
                if currentTurn.isEmpty == false {
                    turns.append(currentTurn)
                    currentTurn = []
                }
                currentTurn.append(message)
            case .assistant, .system:
                if currentTurn.isEmpty == false {
                    currentTurn.append(message)
                } else {
                    currentTurn = [message]
                }
            }
        }

        if currentTurn.isEmpty == false {
            turns.append(currentTurn)
        }

        let recentTurns = turns.suffix(limit)
        return recentTurns.flatMap { $0 }
    }
}
