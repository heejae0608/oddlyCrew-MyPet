//
//  ChatUseCase.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import Foundation

struct ChatHistoryResult {
    let messages: [ChatMessage]
    let conversation: ChatConversation?

    var status: ChatConversation.Status? {
        conversation?.status
    }

    var lastAssistantMessage: ChatMessage? {
        messages.reversed().first(where: { $0.role == .assistant })
    }
}

protocol ChatUseCaseInterface {
    func history(for petId: UUID?) -> [ChatMessage]
    func loadLastConversation(for pet: Pet) async -> ChatHistoryResult
    func append(_ message: ChatMessage)
    func clearHistory(for petId: UUID?)
    func startNewConversation(for petId: UUID)
    func saveCurrentMessages(conversationId: UUID, messages: [ChatMessage]) async throws
    func send(messages: [ChatMessage], pet: Pet?) -> AnyPublisher<AssistantReply, Error>
    func updateConversationStatus(conversationId: UUID, status: ChatConversation.Status) async
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

    func loadLastConversation(for pet: Pet) async -> ChatHistoryResult {
        Log.debug("최근 대화 세션 불러오기 시작 (petId: \(pet.id))", tag: "ChatUseCase")

        do {
            let conversations = try await chatConversationRepository
                .getConversations(for: pet.id)
                .sorted { $0.lastUpdated > $1.lastUpdated }

            guard conversations.isEmpty == false else {
                Log.debug("저장된 대화 세션 없음", tag: "ChatUseCase")
                let legacy = await loadLegacyConversationIfNeeded(for: pet)
                let limited = limitMessagesToRecentTurns(legacy, limit: maxTurnCount)
                return ChatHistoryResult(messages: limited, conversation: nil)
            }

            let activeConversation: ChatConversation? = {
                if let currentId = pet.currentConversationId,
                   let existing = conversations.first(where: { $0.id == currentId }) {
                    return existing
                }
                return conversations.first(where: { $0.status == .inProgress }) ?? conversations.first
            }()

            if let activeConversation,
               activeConversation.status == .inProgress,
               pet.currentConversationId != activeConversation.id {
                var updatedPet = pet
                updatedPet.currentConversationId = activeConversation.id
                try await petRepository.updatePet(updatedPet)
                Log.debug("currentConversationId 갱신 (id: \(activeConversation.id))", tag: "ChatUseCase")
            } else if (activeConversation == nil || activeConversation?.status != .inProgress),
                      pet.currentConversationId != nil {
                var updatedPet = pet
                updatedPet.currentConversationId = nil
                try await petRepository.updatePet(updatedPet)
                Log.debug("활성 세션 없음 - currentConversationId 초기화", tag: "ChatUseCase")
            }

            guard let conversation = activeConversation ?? conversations.first else {
                Log.debug("활성 세션을 찾지 못해 레거시 데이터 확인", tag: "ChatUseCase")
                let legacy = await loadLegacyConversationIfNeeded(for: pet)
                let limited = limitMessagesToRecentTurns(legacy, limit: maxTurnCount)
                return ChatHistoryResult(messages: limited, conversation: nil)
            }

            let resolvedMessages = resolveMessages(from: conversation, petId: pet.id)
            let messagesToUse: [ChatMessage]

            if resolvedMessages.isEmpty {
                let fallback = fallbackMessages(from: conversation, petId: pet.id)
                messagesToUse = fallback

                if fallback.isEmpty {
                    Log.debug("선택된 세션에 저장된 메시지가 없어 빈 배열 반환", tag: "ChatUseCase")
                }
            } else {
                messagesToUse = resolvedMessages
            }

            let sortedMessages = messagesToUse.sorted { $0.timestamp < $1.timestamp }
            
            // ⚠️ 중요: UI 표시용으로만 6턴 제한, 실제 전송 시에는 전체 히스토리 사용
            // limitMessagesToRecentTurns를 제거하면 GPT에 전체 히스토리 전송 가능
            let limitedMessages = limitMessagesToRecentTurns(sortedMessages, limit: maxTurnCount)

            Log.info("✅ 최신 대화 세션 로드 완료 (세션 ID: \(conversation.id), 메시지 수: \(sortedMessages.count), UI 표시: \(limitedMessages.count))", tag: "ChatUseCase")
            Log.info("📋 전체 메시지 저장됨 (conversation.messages에 \(sortedMessages.count)개)", tag: "ChatUseCase")
            
            // ⚠️ 중요: 전체 메시지를 conversation에 저장 (GPT 전송 시 사용)
            var updatedConversation = conversation
            updatedConversation.updateMessages(sortedMessages)
            try? await chatConversationRepository.saveConversation(updatedConversation)
            
            return ChatHistoryResult(messages: limitedMessages, conversation: updatedConversation)
        } catch {
            Log.error("대화 이력 불러오기 실패: \(error.localizedDescription)", tag: "ChatUseCase")
            return ChatHistoryResult(messages: [], conversation: nil)
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
                        if let conversationId = pet.currentConversationId {
                            try await chatConversationRepository.updateConversationStatus(
                                conversationId: conversationId,
                                status: .closed
                            )
                        }
                        var updatedPet = pet
                        updatedPet.currentConversationId = nil
                        updatedPet.responseId = nil
                        try await petRepository.updatePet(updatedPet)
                        Log.info("대화 세션 초기화 완료 (petId: \(petId.uuidString))", tag: "ChatUseCase")
                    }
                } else {
                    for pet in petRepository.pets {
                        if let conversationId = pet.currentConversationId {
                            try await chatConversationRepository.updateConversationStatus(
                                conversationId: conversationId,
                                status: .closed
                            )
                        }
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

    func saveCurrentMessages(conversationId: UUID, messages: [ChatMessage]) async throws {
        Log.info("💾 현재 대화 메시지 저장 시작 (conversationId: \(conversationId), 메시지 수: \(messages.count))", tag: "ChatUseCase")
        try await chatConversationRepository.updateConversationMessages(
            conversationId: conversationId,
            messages: messages
        )
        Log.info("✅ 현재 대화 메시지 저장 완료", tag: "ChatUseCase")
    }
    
    func startNewConversation(for petId: UUID) {
        Task {
            do {
                if let pet = petRepository.pets.first(where: { $0.id == petId }) {
                    if let conversationId = pet.currentConversationId {
                        try await chatConversationRepository.updateConversationStatus(
                            conversationId: conversationId,
                            status: .closed
                        )
                    }
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
        return Future<(ChatConversation?, String?, [ChatMessage]), Error> { promise in
            Task {
                do {
                    guard let petId = resolvedPet?.id else {
                        promise(.success((nil, nil, messages)))
                        return
                    }

                    var currentConversation: ChatConversation?
                    var previousSummary: String?
                    var messagesToSend = messages

                    // 현재 활성 대화 세션 확인
                    if let conversationId = resolvedPet?.currentConversationId {
                        Log.debug("🔍 기존 대화 세션 조회 중 (id: \(conversationId))", tag: "ChatUseCase")
                        currentConversation = try await self.chatConversationRepository.getConversation(by: conversationId)

                        if let conversation = currentConversation {
                            // 완료 또는 종료된 세션이면 새 세션 시작
                            if conversation.status == .completed || conversation.status == .closed {
                                Log.debug("✅ 기존 대화 세션이 종료 상태 - 새 세션 생성", tag: "ChatUseCase")
                                currentConversation = nil // 새 세션 생성하도록
                            } else {
                                // ⚠️ 중요: GPT 전송용 전체 히스토리는 Firestore에서 로드
                                if conversation.messages.isEmpty == false {
                                    let fullHistory = conversation.messages.sorted { $0.timestamp < $1.timestamp }
                                    // ViewModel의 messages (최근만 있음) 대신 전체 히스토리 사용
                                    messagesToSend = fullHistory
                                    Log.info("📚 전체 히스토리 로드: \(fullHistory.count)개 (ViewModel: \(messages.count)개)", tag: "ChatUseCase")
                                }
                                
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
                                Log.debug("  - 상태: \(conversation.status)", tag: "ChatUseCase")
                                Log.debug("  - 전체 메시지: \(conversation.messages.count)개", tag: "ChatUseCase")
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

                    promise(.success((currentConversation, previousSummary, messagesToSend)))
                } catch {
                    Log.error("대화 세션 준비 실패: \(error.localizedDescription)", tag: "ChatUseCase")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
        .flatMap { (conversation, previousSummary, messagesToSend) in
            return self.chatService.send(messages: messagesToSend, pet: resolvedPet, previousSummary: previousSummary)
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

                        if let responseId = result.conversationId {
                            // 요약이 없으면 메시지 내용의 일부를 사용
                            let summary: String
                            if let providedSummary = result.reply.conversationSummary,
                               !providedSummary.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                                summary = providedSummary
                            } else {
                                // 요약이 없으면 메시지 앞부분을 요약으로 사용
                                summary = String(result.reply.message.prefix(100))
                            }

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
                            Log.debug("❌ 응답 저장 건너뛰기 - responseId 없음", tag: "ChatUseCase")
                        }

                        // 전체 메시지 로그 저장 (사용자 + AI)
                        // ⚠️ 중요: 기존 저장된 전체 메시지를 로드해서 병합해야 함
                        Log.debug("📥 메시지 병합 시작", tag: "ChatUseCase")
                        Log.debug("  - ViewModel에서 받은 messages: \(messages.count)개", tag: "ChatUseCase")
                        for (idx, msg) in messages.enumerated() {
                            Log.debug("    [\(idx)] \(msg.role) - id: \(msg.id.uuidString.prefix(8))... - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                        }
                        
                        let existingConversation = try await self.chatConversationRepository.getConversation(by: conversation.id)
                        let existingMessages = existingConversation?.messages ?? []
                        
                        Log.debug("  - Firestore에서 로드한 기존 messages: \(existingMessages.count)개", tag: "ChatUseCase")
                        for (idx, msg) in existingMessages.enumerated() {
                            Log.debug("    [\(idx)] \(msg.role) - id: \(msg.id.uuidString.prefix(8))... - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                        }
                        
                        // 새로 추가된 메시지만 추출 (기존에 없는 것만)
                        let newMessages = self.buildUpdatedMessages(from: messages, assistantMessage: assistantMessage)
                        Log.debug("  - buildUpdatedMessages 결과: \(newMessages.count)개", tag: "ChatUseCase")
                        for (idx, msg) in newMessages.enumerated() {
                            Log.debug("    [\(idx)] \(msg.role) - id: \(msg.id.uuidString.prefix(8))... - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                        }
                        
                        // 중복 체크: UUID 대신 role + content로 비교
                        // (ViewModel과 UseCase가 각각 ChatMessage를 생성해서 UUID가 다를 수 있음)
                        // timestamp는 밀리초 단위로 달라질 수 있으므로 제외
                        let existingSignatures = Set(existingMessages.map { "\($0.role.rawValue)_\($0.content)" })
                        let messagesToAdd = newMessages.filter { msg in
                            let signature = "\(msg.role.rawValue)_\(msg.content)"
                            let isDuplicate = existingSignatures.contains(signature)
                            if isDuplicate {
                                Log.debug("    ⚠️ 중복 메시지 감지: \(msg.role) - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                            }
                            return !isDuplicate
                        }
                        
                        Log.debug("  - 중복 제거 후 추가할 메시지: \(messagesToAdd.count)개", tag: "ChatUseCase")
                        for (idx, msg) in messagesToAdd.enumerated() {
                            Log.debug("    [\(idx)] \(msg.role) - id: \(msg.id.uuidString.prefix(8))... - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                        }
                        
                        // 기존 + 새로운 메시지 병합
                        let allMessages = existingMessages + messagesToAdd
                        let sortedMessages = allMessages.sorted { $0.timestamp < $1.timestamp }
                        
                        Log.debug("  - 최종 저장할 메시지: \(sortedMessages.count)개", tag: "ChatUseCase")
                        for (idx, msg) in sortedMessages.enumerated() {
                            Log.debug("    [\(idx)] \(msg.role) - id: \(msg.id.uuidString.prefix(8))... - \(msg.content.prefix(30))...", tag: "ChatUseCase")
                        }
                        
                        try await self.chatConversationRepository.updateConversationMessages(
                            conversationId: conversation.id,
                            messages: sortedMessages
                        )
                        Log.debug("💾 대화 메시지 로그 저장 완료", tag: "ChatUseCase")

                        // 상담 완료 처리 (하지만 세션은 유지)
                        if result.reply.status == .providingAnswer {
                            Log.info("🏁 상담 완료 - 하지만 계속 대화 가능하도록 세션 유지", tag: "ChatUseCase")

                            try await self.chatConversationRepository.updateConversationStatus(
                                conversationId: conversation.id,
                                status: .completed
                            )

                            Log.debug("  - 세션 상태: 완료됨 (계속 대화 가능)", tag: "ChatUseCase")
                            Log.debug("  - currentConversationId: 유지됨", tag: "ChatUseCase")
                        } else {
                            try await self.chatConversationRepository.updateConversationStatus(
                                conversationId: conversation.id,
                                status: .inProgress
                            )
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

    func updateConversationStatus(conversationId: UUID, status: ChatConversation.Status) async {
        do {
            try await chatConversationRepository.updateConversationStatus(conversationId: conversationId, status: status)
        } catch {
            Log.error("대화 상태 업데이트 실패: \(error.localizedDescription)", tag: "ChatUseCase")
        }
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
