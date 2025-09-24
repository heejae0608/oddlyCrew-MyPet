//
//  HistoryViewModel.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var selectedPet: Pet? {
        didSet { updateFilteredConversations() }
    }
    @Published private(set) var chatConversations: [ChatConversation] = []
    @Published private(set) var filteredConversations: [ChatConversation] = []
    @Published private(set) var pets: [Pet] = []

    private let session: SessionViewModel
    private let chatUseCase: ChatUseCaseInterface
    private let conversationRepository: ConversationRepositoryInterface
    private let chatConversationRepository: ChatConversationRepositoryInterface
    private var cancellables = Set<AnyCancellable>()

    init(session: SessionViewModel, chatUseCase: ChatUseCaseInterface, conversationRepository: ConversationRepositoryInterface, chatConversationRepository: ChatConversationRepositoryInterface) {
        self.session = session
        self.chatUseCase = chatUseCase
        self.conversationRepository = conversationRepository
        self.chatConversationRepository = chatConversationRepository
        bind()
        loadHistory()
    }

    func loadHistory() {
        Task {
            do {
                var allChatConversations: [ChatConversation] = []
                for pet in pets {
                    let petConversations = try await chatConversationRepository.getConversations(for: pet.id)
                    allChatConversations.append(contentsOf: petConversations)
                }
                await MainActor.run {
                    self.chatConversations = allChatConversations.sorted { $0.lastUpdated > $1.lastUpdated }
                    self.updateFilteredConversations()
                }
            } catch {
                Log.error("대화 히스토리 로드 실패: \(error.localizedDescription)", tag: "HistoryViewModel")
                await MainActor.run {
                    self.chatConversations = []
                    self.filteredConversations = []
                }
            }
        }
    }

    private func updateFilteredConversations() {
        if let selectedPet {
            filteredConversations = chatConversations.filter { $0.petId == selectedPet.id }
        } else {
            filteredConversations = chatConversations
        }
    }

    func clearHistory(for pet: Pet?) {
        chatUseCase.clearHistory(for: pet?.id)
        loadHistory()
    }

    func selectAll() {
        selectedPet = nil
    }

    private func bind() {
        // Pets 변경 감지
        session.$pets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pets in
                guard let self else { return }
                self.pets = pets

                if let current = self.selectedPet,
                   let updatedPet = self.pets.first(where: { $0.id == current.id }) {
                    self.selectedPet = updatedPet
                } else if let current = self.selectedPet,
                   self.pets.contains(where: { $0.id == current.id }) == false {
                    self.selectedPet = self.pets.first
                } else if self.selectedPet == nil {
                    self.selectedPet = self.pets.first
                }

                if self.pets.isEmpty {
                    self.selectedPet = nil
                }

                self.loadHistory()
            }
            .store(in: &cancellables)

        // ChatConversations 변경 실시간 감지
        chatConversationRepository.conversationsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                guard let self else { return }
                self.chatConversations = conversations.sorted { $0.lastUpdated > $1.lastUpdated }
                self.updateFilteredConversations()
            }
            .store(in: &cancellables)
    }
}
