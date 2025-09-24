//
//  AuthUseCase.swift
//  MyPet
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
    func restoreSession() async throws
}

final class AuthUseCase: AuthUseCaseInterface {
    private let userRepository: UserRepositoryInterface
    private let petRepository: PetRepositoryInterface
    private let firebaseAuthService: FirebaseAuthServiceProtocol
    private let remoteUserDataSource: RemoteUserDataSource

    init(
        userRepository: UserRepositoryInterface,
        petRepository: PetRepositoryInterface,
        firebaseAuthService: FirebaseAuthServiceProtocol,
        remoteUserDataSource: RemoteUserDataSource
    ) {
        self.userRepository = userRepository
        self.petRepository = petRepository
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

        // 앱 시작 시 모든 펫의 대화 세션 초기화
        Task {
            await clearAllChatSessions()
        }
    }

    private func clearAllChatSessions() async {
        Log.info("앱 시작 - 모든 펫의 대화 세션 초기화", tag: "AuthUseCase")

        let pets = petRepository.pets
        for pet in pets {
            if pet.currentConversationId != nil || pet.responseId != nil {
                Log.debug("펫 '\(pet.name)'의 대화 세션 초기화 (앱 시작)", tag: "AuthUseCase")
                var cleanedPet = pet
                cleanedPet.currentConversationId = nil
                cleanedPet.responseId = nil
                try? await petRepository.updatePet(cleanedPet)
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) async throws {
        Log.info("Apple 로그인 시도 (Firebase 인증) - nonce prefix: \(nonce.prefix(6))", tag: "AuthUseCase")
        let firebaseUser = try await firebaseAuthService.signInWithApple(idToken: idToken, nonce: nonce)
        Log.info("Firebase 인증 성공: \(firebaseUser.uid)", tag: "AuthUseCase")
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
        Log.info("Firestore 사용자 동기화 완료: \(domainUser.appleUserID)", tag: "AuthUseCase")
        userRepository.login(user: domainUser)

        // Pet 데이터를 별도로 로드
        try await petRepository.loadPets(for: domainUser.id)

        do {
            let refreshedToken = try await firebaseAuthService.fetchIDToken(forceRefresh: true)
            if let refreshedToken {
                Log.debug("로그인 직후 ID 토큰 갱신 성공 (prefix: \(refreshedToken.prefix(10))...)", tag: "AuthUseCase")
            } else {
                Log.warning("로그인 직후 ID 토큰이 비어 있습니다", tag: "AuthUseCase")
            }
        } catch {
            Log.warning("로그인 직후 ID 토큰 갱신 실패: \(error.localizedDescription)", tag: "AuthUseCase")
        }
    }

    func logout() async throws {
        Log.info("로그아웃 시도", tag: "AuthUseCase")
        try firebaseAuthService.signOut()
        userRepository.logout()
        petRepository.clearAllPets()
        Log.info("로그아웃 완료", tag: "AuthUseCase")
    }

    func restoreSession() async throws {
        guard let firebaseUser = firebaseAuthService.currentUser() else {
            Log.info("Firebase 세션 없음 - 사용자 로그아웃", tag: "AuthUseCase")
            userRepository.logout()
            petRepository.clearAllPets()
            return
        }

        Log.info("Firebase 세션 발견: \(firebaseUser.uid)", tag: "AuthUseCase")

        do {
            let _ = try await firebaseAuthService.fetchIDToken(forceRefresh: false)
            Log.debug("Firebase ID 토큰 검증 완료 (refresh=false)", tag: "AuthUseCase")
            if let remoteUser = try await remoteUserDataSource.fetchUser(uid: firebaseUser.uid) {
                Log.info("Firestore 사용자 복원 성공: \(remoteUser.appleUserID)", tag: "AuthUseCase")
                userRepository.login(user: remoteUser)

                // Pet 데이터를 별도로 로드하고 responseId 초기화
                try await petRepository.loadPets(for: remoteUser.id)
                let pets = petRepository.pets
                for pet in pets {
                    var updatedPet = pet
                    updatedPet.responseId = nil
                    try await petRepository.updatePet(updatedPet)
                }
                Log.debug("앱 시작 시 모든 responseId 초기화 완료 (펫 수: \(pets.count))", tag: "AuthUseCase")
            } else {
                Log.warning("Firestore 사용자 없음, 신규 생성 진행: \(firebaseUser.uid)", tag: "AuthUseCase")
                let resolvedName = firebaseUser.name ?? "사용자"
                let newUser = User(
                    appleUserID: firebaseUser.uid,
                    name: resolvedName,
                    email: firebaseUser.email
                )
                try await remoteUserDataSource.upsertUser(newUser)
                Log.info("Firestore 사용자 생성 후 복원: \(newUser.appleUserID)", tag: "AuthUseCase")
                userRepository.login(user: newUser)

                // 신규 사용자는 Pet이 없으므로 빈 배열 로드
                try await petRepository.loadPets(for: newUser.id)
            }
        } catch let tokenError as NSError where tokenError.code == AuthErrorCode.userTokenExpired.rawValue {
            Log.warning("Firebase ID 토큰 만료 감지 - 사용자 로그아웃", tag: "AuthUseCase")
            userRepository.logout()
            petRepository.clearAllPets()
            throw tokenError
        } catch {
            Log.error("세션 복원 실패: \(error.localizedDescription)", tag: "AuthUseCase")
            throw error
        }
    }
}
