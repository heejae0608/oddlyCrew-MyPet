//
//  ChatViewModel.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messageText: String = ""
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading: Bool = false
    @Published var selectedPet: Pet?
    @Published private(set) var latestAssistantReply: AssistantReply?
    @Published var alert: AppAlert?

    private let session: SessionViewModel
    private let chatUseCase: ChatUseCaseInterface
    private var cancellables = Set<AnyCancellable>()

    // 펫별 메시지 캐시 (현재 세션 동안만 유지)
    private var messagesByPet: [UUID: [ChatMessage]] = [:]

    init(session: SessionViewModel, chatUseCase: ChatUseCaseInterface) {
        self.session = session
        self.chatUseCase = chatUseCase
        bind()
        loadInitialState()
    }

    func loadInitialState() {
        if selectedPet == nil {
            selectedPet = session.pets.first
        }
        loadHistory()
    }

    func loadHistory() {
        guard let pet = selectedPet else {
            messages = []
            return
        }

        // 기존 세션 메시지 먼저 확인
        let petId = pet.id
        if let existingMessages = messagesByPet[petId], !existingMessages.isEmpty {
            messages = existingMessages
            return
        }

        Task {
            let lastConversationMessages = await chatUseCase.loadLastConversation(for: pet)
            await MainActor.run {
                if lastConversationMessages.isEmpty {
                    self.messages = []
                    self.messagesByPet[petId] = []
                } else {
                    self.messages = lastConversationMessages
                    self.messagesByPet[petId] = lastConversationMessages
                    Log.info("🔄 이전 대화 세션 불러옴 - 메시지 수: \(lastConversationMessages.count)", tag: "Chat")
                }
            }
        }
    }

    func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        let startTime = Date()
        let petInfo = selectedPet.map { "\($0.name) (\($0.species))" } ?? "없음"
        Log.info("💬 메시지 전송 시작 - 반려동물: \(petInfo)", tag: "Chat")

        // 펫 정보는 이제 시스템 메시지에서 처리하므로, 사용자 메시지는 순수 질문만
        let userMessage = ChatMessage.user(trimmed, petId: selectedPet?.id)
        appendToTimeline(userMessage)
        messageText = ""
        isLoading = true

        Log.info("📤 ChatUseCase로 메시지 전달", tag: "Chat")

        chatUseCase.send(messages: messages, pet: selectedPet)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.isLoading = false
                    let duration = Date().timeIntervalSince(startTime)

                    if case .failure(let error) = completion {
                        Log.error("❌ 메시지 전송 실패 - 소요시간: \(String(format: "%.2f", duration))초, 에러: \(error.localizedDescription)", tag: "Chat")
                        self.presentError(error)
                    }
                },
                receiveValue: { [weak self] reply in
                    guard let self else { return }
                    let duration = Date().timeIntervalSince(startTime)

                    Log.info("✅ 메시지 전송 완료 - 총 소요시간: \(String(format: "%.2f", duration))초", tag: "Chat")
                    Log.info("🎯 AI 응답 - 긴급도: \(reply.urgencyLevel), 수의사 상담 필요: \(reply.vetConsultationNeeded)", tag: "Chat")

                    // UI 업데이트를 애니메이션과 함께
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.latestAssistantReply = reply
                    }
                    let assistantMessage = ChatMessage.assistant(reply.message, petId: self.selectedPet?.id)
                    self.appendToTimeline(assistantMessage)

                    // 상담 완료 시 자동 새 대화 준비
                    if reply.status == .providingAnswer {
                        Log.info("🎯 상담 완료 - UI에서 새로운 대화 준비", tag: "Chat")
                        // 선택적: 몇 초 후 입력창에 placeholder 변경이나 안내 메시지
                    }
                }
            )
            .store(in: &cancellables)
    }

    func clearChat() {
        let petInfo = selectedPet.map { "\($0.name) (\($0.species))" } ?? "없음"
        Log.info("🗑️ 채팅 기록 삭제 - 반려동물: \(petInfo)", tag: "Chat")

        messages.removeAll()
        if let petId = selectedPet?.id {
            messagesByPet[petId] = []
        }
        chatUseCase.clearHistory(for: selectedPet?.id)
        latestAssistantReply = nil

        Log.info("✅ 채팅 기록 삭제 완료", tag: "Chat")
    }

    func selectPet(_ pet: Pet?) {
        let petInfo = pet.map { "\($0.name) (\($0.species))" } ?? "없음"
        Log.info("🐾 반려동물 변경: \(petInfo)", tag: "Chat")

        selectedPet = pet
        latestAssistantReply = nil  // 펫 변경 시 이전 AI 응답 정보 초기화
        loadHistory()

        Log.info("📜 히스토리 로드 완료 - 메시지 수: \(messages.count)개", tag: "Chat")
    }

    private func bind() {
        session.$pets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pets in
                guard let self else { return }

                if pets.isEmpty {
                    self.messages.removeAll()
                    self.selectedPet = nil
                    return
                }

                if let current = self.selectedPet,
                   pets.contains(where: { $0.id == current.id }) == false {
                    self.selectedPet = pets.first
                } else if self.selectedPet == nil {
                    self.selectedPet = pets.first
                }

                self.loadHistory()
            }
            .store(in: &cancellables)
    }

    private func appendToTimeline(_ message: ChatMessage) {
        // 현재 세션 동안만 UI에 표시
        messages.append(message)

        // 펫별 메시지 캐시에도 저장
        if let petId = selectedPet?.id {
            var petMessages = messagesByPet[petId] ?? []
            petMessages.append(message)
            messagesByPet[petId] = petMessages
        }
    }

    private func presentError(_ error: Error) {
        latestAssistantReply = nil
        let fallbackMessage = ChatMessage.assistant("죄송합니다. 오류가 발생했습니다: \(error.localizedDescription)", petId: selectedPet?.id)
        appendToTimeline(fallbackMessage)
        alert = AppAlert(message: "상담 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.", kind: .generic)
    }

    private func makeOutboundMessage(question: String) -> String {
        guard let pet = selectedPet,
              let payload = MessageWithPetInfoPayload(question: question, pet: pet)
        else {
            return question
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        if let data = try? encoder.encode(payload),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return question
    }

    func startNewConversation() {
        guard let petId = selectedPet?.id else { return }

        Log.info("🆕 사용자 요청으로 새로운 대화 시작", tag: "Chat")

        // UI 초기화
        messages.removeAll()
        messagesByPet[petId] = []
        latestAssistantReply = nil
        messageText = ""

        // 백엔드에서 새 세션 준비
        chatUseCase.startNewConversation(for: petId)

        Log.debug("새 대화 준비 완료 - UI 초기화됨", tag: "Chat")
    }

}

private struct MessageWithPetInfoPayload: Encodable {
    struct PetInfo: Encodable {
        let type: String
        let breed: String?
        let age: String
        let gender: String
        let neutered: Bool
        let weight: String?
        let existingConditions: String?
    }

    let pet_info: PetInfo
    let question: String

    init?(question: String, pet: Pet) {
        guard question.isEmpty == false else { return nil }

        self.pet_info = PetInfo(
            type: pet.species,
            breed: pet.breed,
            age: "\(pet.calculatedAge)살",
            gender: pet.gender,
            neutered: pet.isNeutered,
            weight: pet.weight.map { "\($0)kg" },
            existingConditions: pet.existingConditions
        )
        self.question = question
    }
}
