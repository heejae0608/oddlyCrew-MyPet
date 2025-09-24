import Combine
@testable import MyPet

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

    func fetchUser(uid: String) async throws -> User? {
        storedUser
    }

    func upsertUser(_ user: User) async throws {
        upsertCallCount += 1
        storedUser = user
    }
}

final class StubFirebaseAuthService: FirebaseAuthServiceProtocol {
    var userInfo: FirebaseUserInfo
    var signInCallCount = 0
    var signOutCallCount = 0
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
}
