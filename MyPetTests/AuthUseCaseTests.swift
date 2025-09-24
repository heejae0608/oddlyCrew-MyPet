import Testing
@testable import MyPet

struct AuthUseCaseTests {
    @Test func signInCreatesUserWhenRemoteMissing() async throws {
        let repository = UserRepository()
        let firebase = StubFirebaseAuthService(
            userInfo: FirebaseUserInfo(uid: "firebase-1", name: "Apple User", email: "apple@example.com")
        )
        let remote = StubRemoteUserDataSource()
        let useCase = AuthUseCase(
            userRepository: repository,
            firebaseAuthService: firebase,
            remoteUserDataSource: remote
        )

        try await useCase.signInWithApple(idToken: "token", nonce: "nonce", name: "홍길동", email: "hong@example.com")

        #expect(firebase.signInCallCount == 1)
        #expect(remote.upsertCallCount == 1)
        let user = repository.currentUser
        #expect(user?.appleUserID == "firebase-1")
        #expect(user?.name == "홍길동")
        #expect(user?.email == "hong@example.com")
    }

    @Test func signInUpdatesExistingRemoteUser() async throws {
        var existing = User(appleUserID: "firebase-2", name: "Old Name", email: "old@example.com")
        existing.pets = [.sampleDog]
        let repository = UserRepository()
        let firebase = StubFirebaseAuthService(
            userInfo: FirebaseUserInfo(uid: "firebase-2", name: "Apple User", email: "apple@example.com")
        )
        let remote = StubRemoteUserDataSource()
        remote.storedUser = existing

        let useCase = AuthUseCase(
            userRepository: repository,
            firebaseAuthService: firebase,
            remoteUserDataSource: remote
        )

        try await useCase.signInWithApple(idToken: "token", nonce: "nonce", name: "새 이름", email: nil)

        let user = repository.currentUser
        #expect(user?.name == "새 이름")
        #expect(user?.email == "apple@example.com")
        #expect(user?.pets == [.sampleDog])
        #expect(remote.upsertCallCount == 1)
    }

    @Test func logoutClearsRepositoryAndCallsFirebase() async throws {
        let repository = UserRepository()
        repository.login(user: User(appleUserID: "firebase-3", name: "사용자"))
        let firebase = StubFirebaseAuthService()
        let remote = StubRemoteUserDataSource()
        let useCase = AuthUseCase(
            userRepository: repository,
            firebaseAuthService: firebase,
            remoteUserDataSource: remote
        )

        try await useCase.logout()

        #expect(firebase.signOutCallCount == 1)
        #expect(repository.currentUser == nil)
    }

    @Test func restoreSessionLoadsExistingRemoteUser() async throws {
        let existing = User(appleUserID: "firebase-4", name: "기존 사용자", email: "existing@example.com")
        let repository = UserRepository()
        let firebase = StubFirebaseAuthService(
            userInfo: FirebaseUserInfo(uid: "firebase-4", name: "기존", email: "existing@example.com")
        )
        firebase.currentUserInfo = firebase.userInfo
        let remote = StubRemoteUserDataSource()
        remote.storedUser = existing

        let useCase = AuthUseCase(
            userRepository: repository,
            firebaseAuthService: firebase,
            remoteUserDataSource: remote
        )

        try await useCase.restoreSession()

        let user = repository.currentUser
        #expect(user == existing)
        #expect(remote.upsertCallCount == 0)
    }

    @Test func restoreSessionCreatesUserWhenRemoteMissing() async throws {
        let repository = UserRepository()
        let firebase = StubFirebaseAuthService(
            userInfo: FirebaseUserInfo(uid: "firebase-5", name: "새 사용자", email: "new@example.com")
        )
        firebase.currentUserInfo = firebase.userInfo
        let remote = StubRemoteUserDataSource()

        let useCase = AuthUseCase(
            userRepository: repository,
            firebaseAuthService: firebase,
            remoteUserDataSource: remote
        )

        try await useCase.restoreSession()

        let user = repository.currentUser
        #expect(user?.appleUserID == "firebase-5")
        #expect(user?.name == "새 사용자")
        #expect(remote.upsertCallCount == 1)
    }
}
