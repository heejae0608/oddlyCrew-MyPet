//
//  AuthUseCase.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import FirebaseAuth

protocol AuthUseCaseInterface {
    var userPublisher: AnyPublisher<User?, Never> { get }
    var currentUser: User? { get }

    func bootstrap()
    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) async throws
    func logout() async throws
    func restoreSession() async throws -> User?
    func deleteAccount() async throws
}

final class AuthUseCase: AuthUseCaseInterface {
    private let userRepository: UserRepositoryInterface
    private let petRepository: PetRepositoryInterface
    private let conversationRepository: ConversationRepositoryInterface
    private let chatConversationRepository: ChatConversationRepositoryInterface
    private let firebaseAuthService: FirebaseAuthServiceProtocol
    private let remoteUserDataSource: RemoteUserDataSource
    private let logTag = "AuthUseCase"

    init(
        userRepository: UserRepositoryInterface,
        petRepository: PetRepositoryInterface,
        conversationRepository: ConversationRepositoryInterface,
        chatConversationRepository: ChatConversationRepositoryInterface,
        firebaseAuthService: FirebaseAuthServiceProtocol,
        remoteUserDataSource: RemoteUserDataSource
    ) {
        self.userRepository = userRepository
        self.petRepository = petRepository
        self.conversationRepository = conversationRepository
        self.chatConversationRepository = chatConversationRepository
        self.firebaseAuthService = firebaseAuthService
        self.remoteUserDataSource = remoteUserDataSource
    }

    var userPublisher: AnyPublisher<User?, Never> {
        userRepository.userPublisher
    }

    var currentUser: User? {
        userRepository.currentUser
    }

    func bootstrap() {
        userRepository.bootstrap()
    }

    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) async throws {
        Log.info("Apple 로그인 시도 (Firebase 인증) - nonce prefix: \(nonce.prefix(6))", tag: logTag)
        let firebaseUser = try await firebaseAuthService.signInWithApple(idToken: idToken, nonce: nonce)
        Log.info("Firebase 인증 성공: \(firebaseUser.uid)", tag: logTag)
        let remoteUser = try await remoteUserDataSource.fetchUser(uid: firebaseUser.uid)

        let resolvedName = name ?? firebaseUser.name ?? "사용자"
        let resolvedEmail = email ?? firebaseUser.email

        var domainUser: User

        if var fetchedUser = remoteUser {
            fetchedUser.name = resolvedName
            if let resolvedEmail {
                fetchedUser.email = resolvedEmail
            }
            domainUser = fetchedUser
        } else {
            domainUser = User(
                appleUserID: firebaseUser.uid,
                name: resolvedName,
                email: resolvedEmail
            )
        }

        try await remoteUserDataSource.upsertUser(domainUser)
        Log.info("Firestore 사용자 동기화 완료: \(domainUser.appleUserID)", tag: logTag)
        userRepository.login(user: domainUser)

        // Pet 데이터를 별도로 로드하고 세션 정리는 비동기 처리
        try await petRepository.loadPets(for: domainUser.id)
        Task { await self.resetChatSessionsIfNeeded() }

        do {
            let refreshedToken = try await firebaseAuthService.fetchIDToken(forceRefresh: true)
            if let refreshedToken {
                Log.debug("로그인 직후 ID 토큰 갱신 성공 (prefix: \(refreshedToken.prefix(10))...)", tag: logTag)
            } else {
                Log.warning("로그인 직후 ID 토큰이 비어 있습니다", tag: logTag)
            }
        } catch {
            Log.warning("로그인 직후 ID 토큰 갱신 실패: \(error.localizedDescription)", tag: logTag)
        }
    }

    func logout() async throws {
        Log.info("로그아웃 시도", tag: logTag)
        try firebaseAuthService.signOut()
        userRepository.logout()
        petRepository.clearAllPets()
        Log.info("로그아웃 완료", tag: logTag)
    }

    func restoreSession() async throws -> User? {
        guard let firebaseUser = firebaseAuthService.currentUser() else {
            Log.info("Firebase 세션 없음 - 사용자 로그아웃", tag: logTag)
            userRepository.logout()
            petRepository.clearAllPets()
            return nil
        }

        Log.info("Firebase 세션 발견: \(firebaseUser.uid)", tag: logTag)

        do {
            let _ = try await firebaseAuthService.fetchIDToken(forceRefresh: false)
            Log.debug("Firebase ID 토큰 검증 완료 (refresh=false)", tag: logTag)
            if let remoteUser = try await remoteUserDataSource.fetchUser(uid: firebaseUser.uid) {
                Log.info("Firestore 사용자 복원 성공: \(remoteUser.appleUserID)", tag: logTag)
                userRepository.login(user: remoteUser)

                // Pet 데이터를 로드하고 필요한 경우 대화 세션을 초기화
                try await petRepository.loadPets(for: remoteUser.id)
                Task { await self.resetChatSessionsIfNeeded() }
                return remoteUser
            } else {
                Log.warning("Firestore 사용자 없음, 신규 생성 진행: \(firebaseUser.uid)", tag: logTag)
                let resolvedName = firebaseUser.name ?? "사용자"
                let newUser = User(
                    appleUserID: firebaseUser.uid,
                    name: resolvedName,
                    email: firebaseUser.email
                )
                try await remoteUserDataSource.upsertUser(newUser)
                Log.info("Firestore 사용자 생성 후 복원: \(newUser.appleUserID)", tag: logTag)
                userRepository.login(user: newUser)

                // 신규 사용자는 Pet이 없으므로 빈 배열 로드
                try await petRepository.loadPets(for: newUser.id)
                return newUser
            }
        } catch let tokenError as NSError where tokenError.code == AuthErrorCode.userTokenExpired.rawValue {
            Log.warning("Firebase ID 토큰 만료 감지 - 사용자 로그아웃", tag: logTag)
            userRepository.logout()
            petRepository.clearAllPets()
            throw tokenError
        } catch {
            Log.error("세션 복원 실패: \(error.localizedDescription)", tag: logTag)
            throw error
        }

        return nil
    }

    func deleteAccount() async throws {
        guard let user = currentUser else {
            Log.warning("삭제할 사용자 정보가 없습니다", tag: logTag)
            throw NSError(domain: "AuthUseCase", code: -1, userInfo: [NSLocalizedDescriptionKey: "삭제할 계정이 없습니다."])
        }

        Log.info("계정 삭제 시도: \(user.appleUserID)", tag: logTag)

        let pets = petRepository.pets

        for pet in pets {
            do {
                let chatConversations = try await chatConversationRepository.getConversations(for: pet.id)
                for conversation in chatConversations {
                    try await chatConversationRepository.deleteConversation(id: conversation.id)
                }
            } catch {
                Log.warning("채팅 대화 삭제 실패 (petId: \(pet.id.uuidString)): \(error.localizedDescription)", tag: logTag)
            }

            do {
                let legacyConversations = try await conversationRepository.getConversations(for: pet.id)
                for conversation in legacyConversations {
                    try await conversationRepository.deleteConversation(id: conversation.id)
                }
            } catch {
                Log.warning("레거시 대화 삭제 실패 (petId: \(pet.id.uuidString)): \(error.localizedDescription)", tag: logTag)
            }

            do {
                try await petRepository.removePet(with: pet.id)
            } catch {
                Log.warning("펫 삭제 실패 (petId: \(pet.id.uuidString)): \(error.localizedDescription)", tag: logTag)
            }
        }

        petRepository.clearAllPets()

        do {
            try await remoteUserDataSource.deleteUser(uid: user.appleUserID)
        } catch {
            Log.warning("Firestore 사용자 삭제 실패: \(error.localizedDescription)", tag: logTag)
            throw error
        }

        do {
            try await firebaseAuthService.deleteAccount()
        } catch {
            Log.warning("FirebaseAuth 계정 삭제 실패: \(error.localizedDescription)", tag: logTag)
            throw error
        }

        userRepository.logout()
        Log.info("계정 삭제 완료", tag: logTag)
    }

    private func resetChatSessionsIfNeeded() async {
        let pets = petRepository.pets
        guard pets.isEmpty == false else { return }

        for pet in pets {
            guard pet.currentConversationId != nil || pet.responseId != nil else { continue }

            var cleanedPet = pet
            cleanedPet.currentConversationId = nil
            cleanedPet.responseId = nil

            do {
                try await petRepository.updatePet(cleanedPet)
                Log.debug("펫 '\(pet.name)'의 대화 세션 초기화", tag: logTag)
            } catch {
                Log.warning("펫 '\(pet.name)' 세션 초기화 실패: \(error.localizedDescription)", tag: logTag)
            }
        }
    }
}
