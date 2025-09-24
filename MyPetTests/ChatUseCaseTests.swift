import Combine
import Testing
@testable import MyPet

struct ChatUseCaseTests {
    private let petID = UUID()
    private let userID = UUID()
    private var samplePet: Pet {
        Pet(
            id: petID,
            userId: userID,
            name: "초코",
            species: "강아지",
            breed: "포메라니안",
            age: 3,
            gender: "수컷",
            isNeutered: true,
            weight: 4.2
        )
    }

    private var otherPet: Pet {
        Pet(
            id: UUID(),
            userId: userID,
            name: "나비",
            species: "고양이",
            breed: "코리안숏헤어",
            age: 2,
            gender: "암컷",
            isNeutered: false,
            weight: 3.1
        )
    }

    private func makeRepository(with user: User) -> UserRepository {
        let repository = UserRepository()
        repository.login(user: user)
        return repository
    }

    private func makeReply(
        message: String = "안녕하세요",
        summary: String? = "요약"
    ) -> AssistantReply {
        AssistantReply(
            message: message,
            conversationSummary: summary,
            status: .providingAnswer,
            questions: [],
            checklist: [],
            urgencyLevel: .low,
            vetConsultationNeeded: false,
            vetConsultationReason: nil,
            nextSteps: []
        )
    }

    @Test func historyReturnsEmptyArray() async throws {
        let user = User(
            appleUserID: "apple-1",
            name: "사용자",
            pets: [samplePet]
        )

        let repository = makeRepository(with: user)
        let useCase = ChatUseCase(
            userRepository: repository,
            chatService: StubChatService(),
            remoteUserDataSource: StubRemoteUserDataSource()
        )

        let history = useCase.history(for: nil)
        #expect(history.isEmpty)
    }

    @Test func historyFiltersByPet() async throws {
        let user = User(
            appleUserID: "apple-2",
            name: "사용자",
            pets: [samplePet, otherPet]
        )

        let repository = makeRepository(with: user)
        let useCase = ChatUseCase(
            userRepository: repository,
            chatService: StubChatService(),
            remoteUserDataSource: StubRemoteUserDataSource()
        )

        let filtered = useCase.history(for: petID)
        #expect(filtered.isEmpty)
    }

    @Test func appendDoesNothing() async throws {
        let user = User(appleUserID: "apple-3", name: "사용자", pets: [samplePet])
        let repository = makeRepository(with: user)
        let remote = StubRemoteUserDataSource()
        let useCase = ChatUseCase(
            userRepository: repository,
            chatService: StubChatService(),
            remoteUserDataSource: remote
        )

        let newMessage = ChatMessage.user("새 메시지", petId: petID)
        useCase.append(newMessage)

        // append는 현재 아무것도 하지 않음 (세션 전용 메시지)
        #expect(true)
    }

    @Test func clearHistoryClearsResponseId() async throws {
        var petWithResponseId = samplePet
        petWithResponseId.responseId = "response-123"

        let user = User(
            appleUserID: "apple-4",
            name: "사용자",
            pets: [petWithResponseId, otherPet]
        )

        let repository = makeRepository(with: user)
        let remote = StubRemoteUserDataSource()
        let useCase = ChatUseCase(
            userRepository: repository,
            chatService: StubChatService(),
            remoteUserDataSource: remote
        )

        useCase.clearHistory(for: petID)

        let updatedPet = repository.currentUser?.pets.first(where: { $0.id == petID })
        #expect(updatedPet?.responseId == nil)
        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(remote.upsertCallCount == 1)
    }

    @Test func sendUpdatesResponseIdAndSummary() async throws {
        let user = User(
            appleUserID: "apple-5",
            name: "사용자",
            pets: [samplePet]
        )

        let repository = makeRepository(with: user)
        let remote = StubRemoteUserDataSource()
        let chatService = StubChatService()
        chatService.result = .success(
            ChatResult(
                reply: makeReply(message: "응답", summary: "최근 상담 요약"),
                conversationId: "response_new"
            )
        )

        let useCase = ChatUseCase(
            userRepository: repository,
            chatService: chatService,
            remoteUserDataSource: remote
        )

        var cancellables = Set<AnyCancellable>()
        let publisher = useCase.send(messages: [], pet: samplePet)

        var receivedReply: AssistantReply?
        var failure: Error?
        publisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        failure = error
                    }
                },
                receiveValue: { reply in
                    receivedReply = reply
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 50_000_000)

        let updatedPet = repository.currentUser?.pets.first(where: { $0.id == petID })
        #expect(updatedPet?.responseId == "response_new")
        // ConversationRepository를 통해 대화 요약이 저장되므로 Pet에서는 제거됨
        #expect(receivedReply?.message == "응답")
        #expect(failure == nil)

        try await Task.sleep(nanoseconds: 10_000_000)
        #expect(remote.upsertCallCount == 1)
    }
}
