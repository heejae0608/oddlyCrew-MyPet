import Combine
@testable import OurPet

final class StubChatService: ChatGPTServicing {
    var lastMessages: [ChatMessage] = []
    var lastPet: Pet?
    var lastPreviousSummary: String?
    var result: Result<ChatResult, Error> = .success(ChatResult(reply: .fallback, conversationId: "conv_stub"))

    func send(messages: [ChatMessage], pet: Pet?, previousSummary: String?) -> AnyPublisher<ChatResult, Error> {
        lastMessages = messages
        lastPet = pet
        lastPreviousSummary = previousSummary
        return result.publisher.eraseToAnyPublisher()
    }
}

final class StubRemoteUserDataSource: RemoteUserDataSource {
    var storedUser: User?
    private(set) var upsertCallCount = 0
    private(set) var deleteCallCount = 0

    func fetchUser(uid: String) async throws -> User? {
        storedUser
    }

    func upsertUser(_ user: User) async throws {
        upsertCallCount += 1
        storedUser = user
    }

    func deleteUser(uid: String) async throws {
        deleteCallCount += 1
        if storedUser?.appleUserID == uid {
            storedUser = nil
        }
    }
}

final class StubFirebaseAuthService: FirebaseAuthServiceProtocol {
    var userInfo: FirebaseUserInfo
    var signInCallCount = 0
    var signOutCallCount = 0
    var deleteCallCount = 0
    var error: Error?
    var currentUserInfo: FirebaseUserInfo?
    var token: String?

    init(userInfo: FirebaseUserInfo = FirebaseUserInfo(uid: "firebase-uid", name: "사용자", email: "user@example.com")) {
        self.userInfo = userInfo
        self.currentUserInfo = nil
        self.token = "stub-token"
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> FirebaseUserInfo {
        signInCallCount += 1
        if let error {
            throw error
        }
        currentUserInfo = userInfo
        token = "stub-token-signed"
        return userInfo
    }

    func signOut() throws {
        signOutCallCount += 1
        if let error {
            throw error
        }
        currentUserInfo = nil
        token = nil
    }

    func currentUser() -> FirebaseUserInfo? {
        currentUserInfo
    }

    func fetchIDToken(forceRefresh: Bool) async throws -> String? {
        if let error {
            throw error
        }
        if forceRefresh {
            token = "stub-token-refreshed"
        }
        return token
    }

    func deleteAccount() async throws {
        deleteCallCount += 1
        if let error {
            throw error
        }
        currentUserInfo = nil
        token = nil
    }
}

final class StubPetRepository: PetRepositoryInterface {
    private let subject = CurrentValueSubject<[Pet], Never>([])

    var petsPublisher: AnyPublisher<[Pet], Never> {
        subject.eraseToAnyPublisher()
    }

    var pets: [Pet] {
        subject.value
    }

    func loadPets(for userId: UUID) async throws {}

    func addPet(_ pet: Pet) async throws {
        var items = subject.value
        items.append(pet)
        subject.send(items)
    }

    func updatePet(_ pet: Pet) async throws {
        var items = subject.value
        if let index = items.firstIndex(where: { $0.id == pet.id }) {
            items[index] = pet
            subject.send(items)
        }
    }

    func removePet(with id: UUID) async throws {
        var items = subject.value
        items.removeAll { $0.id == id }
        subject.send(items)
    }

    func clearAllPets() {
        subject.send([])
    }
}

final class StubConversationRepository: ConversationRepositoryInterface {
    private var storage: [UUID: [Conversation]] = [:]
    private let subject = CurrentValueSubject<[Conversation], Never>([])

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        subject.eraseToAnyPublisher()
    }

    func getConversations(for petId: UUID) async throws -> [Conversation] {
        storage[petId] ?? []
    }

    func getConversation(by responseId: String) async throws -> Conversation? {
        storage.values.flatMap { $0 }.first { $0.responseId == responseId }
    }

    func saveConversation(_ conversation: Conversation) async throws {
        var items = storage[conversation.petId] ?? []
        if let index = items.firstIndex(where: { $0.id == conversation.id }) {
            items[index] = conversation
        } else {
            items.append(conversation)
        }
        storage[conversation.petId] = items
        emit()
    }

    func deleteConversation(id: UUID) async throws {
        for (key, value) in storage {
            let filtered = value.filter { $0.id != id }
            if filtered.count != value.count {
                storage[key] = filtered
            }
        }
        emit()
    }

    private func emit() {
        let all = storage.values.flatMap { $0 }
        subject.send(all)
    }
}

final class StubChatConversationRepository: ChatConversationRepositoryInterface {
    private var storage: [UUID: [ChatConversation]] = [:]
    private let subject = CurrentValueSubject<[ChatConversation], Never>([])

    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> {
        subject.eraseToAnyPublisher()
    }

    func getConversations(for petId: UUID) async throws -> [ChatConversation] {
        storage[petId] ?? []
    }

    func getConversation(by id: UUID) async throws -> ChatConversation? {
        storage.values.flatMap { $0 }.first { $0.id == id }
    }

    func saveConversation(_ conversation: ChatConversation) async throws {
        var items = storage[conversation.petId] ?? []
        if let index = items.firstIndex(where: { $0.id == conversation.id }) {
            items[index] = conversation
        } else {
            items.append(conversation)
        }
        storage[conversation.petId] = items
        emit()
    }

    func deleteConversation(id: UUID) async throws {
        for (key, value) in storage {
            let filtered = value.filter { $0.id != id }
            if filtered.count != value.count {
                storage[key] = filtered
            }
        }
        emit()
    }

    func addResponse(to conversationId: UUID, response: ChatResponse) async throws {
        guard var convo = try await getConversation(by: conversationId) else { return }
        convo.addResponse(response)
        try await saveConversation(convo)
    }

    func updateConversationSummary(conversationId: UUID, fullSummary: String) async throws {
        guard var convo = try await getConversation(by: conversationId) else { return }
        convo.updateFullSummary(fullSummary)
        try await saveConversation(convo)
    }

    func updateConversationMessages(conversationId: UUID, messages: [ChatMessage]) async throws {
        guard var convo = try await getConversation(by: conversationId) else { return }
        convo.updateMessages(messages)
        try await saveConversation(convo)
    }

    func markConversationCompleted(conversationId: UUID) async throws {
        guard var convo = try await getConversation(by: conversationId) else { return }
        convo.markCompleted()
        try await saveConversation(convo)
    }

    private func emit() {
        let all = storage.values.flatMap { $0 }
        subject.send(all)
    }
}
