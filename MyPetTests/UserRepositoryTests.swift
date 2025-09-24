import Combine
import Testing
@testable import MyPet

struct UserRepositoryTests {
    private let sampleUser = User(appleUserID: "apple-1", name: "Lime", email: "lime@example.com")

    @Test func bootstrapStartsWithNilUser() async throws {
        let repository = UserRepository()

        repository.bootstrap()

        #expect(repository.currentUser == nil)
    }

    @Test func loginPublishesUser() async throws {
        let repository = UserRepository()

        var received: [User?] = []
        let cancellable = repository.userPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        repository.bootstrap()
        repository.login(user: sampleUser)

        #expect(repository.currentUser == sampleUser)
        #expect(received.count == 2)
        #expect(received[0] == nil)
        #expect(received.last! == sampleUser)
    }

    @Test func updateUserMutatesCurrentUser() async throws {
        let repository = UserRepository()
        repository.login(user: sampleUser)

        repository.updateUser { user in
            user.name = "Mango"
            user.email = "mango@example.com"
        }

        #expect(repository.currentUser?.name == "Mango")
        #expect(repository.currentUser?.email == "mango@example.com")
    }

    @Test func logoutClearsCurrentUser() async throws {
        let repository = UserRepository()
        repository.login(user: sampleUser)

        var received: [User?] = []
        let cancellable = repository.userPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        repository.logout()

        #expect(repository.currentUser == nil)
        #expect(received.last! == nil)
    }
}
