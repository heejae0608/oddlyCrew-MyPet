//
//  SessionViewModel.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import SwiftUI

enum SessionFlow {
    case splash
    case login
    case main
}

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var pets: [Pet] = []
    @Published private(set) var appState: AppState = .default
    @Published var loadingMessage: String = "잠시만 기다려주세요..."
    @Published private(set) var flow: SessionFlow = .splash


    private let authUseCase: AuthUseCaseInterface
    private let petUseCase: PetUseCaseInterface
    private let petRepository: PetRepositoryInterface
    private var cancellables = Set<AnyCancellable>()
    private var isRestoringSession = true

    init(
        authUseCase: AuthUseCaseInterface,
        petUseCase: PetUseCaseInterface,
        petRepository: PetRepositoryInterface
    ) {
        self.authUseCase = authUseCase
        self.petUseCase = petUseCase
        self.petRepository = petRepository
        bind()
        authUseCase.bootstrap()
        restoreSession()
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    private func bind() {
        authUseCase.userPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                Log.debug("세션 사용자 갱신: \(user?.name ?? "nil")", tag: "Session")
                self.currentUser = user
                if self.isRestoringSession {
                    return
                }
                self.appState = .default
                self.updateFlow(for: user)
            }
            .store(in: &cancellables)

        petRepository.petsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pets in
                guard let self else { return }
                Log.debug("세션 펫 갱신: \(pets.count)마리", tag: "Session")

                // Pet 데이터 그대로 유지 - 대화 세션 건드리지 않음
                self.pets = pets
            }
            .store(in: &cancellables)
    }

    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) {
        loadingMessage = "로그인 중입니다..."
        appState = .loading
        isRestoringSession = true
        Log.info("세션 Apple 로그인 플로우 시작", tag: "Session")
        Task {
            do {
                try await authUseCase.signInWithApple(idToken: idToken, nonce: nonce, name: name, email: email)
                await MainActor.run {
                    self.appState = .default
                    self.flow = .main
                    self.isRestoringSession = false
                }
                Log.info("세션 Apple 로그인 성공", tag: "Session")
            } catch {
                await MainActor.run {
                    self.appState = .error(error.localizedDescription)
                    self.flow = .login
                    self.isRestoringSession = false
                }
                Log.error("세션 Apple 로그인 실패: \(error.localizedDescription)", tag: "Session")
            }
        }
    }

    func logout(reason: String? = nil) {
        loadingMessage = reason ?? "로그아웃 중입니다..."
        appState = .loading
        isRestoringSession = true
        Log.info("세션 로그아웃 플로우 시작", tag: "Session")
        Task {
            do {
                try await authUseCase.logout()
                await MainActor.run {
                    self.appState = .default
                    self.flow = .login
                    self.isRestoringSession = false
                }
                Log.info("세션 로그아웃 성공", tag: "Session")
            } catch {
                await MainActor.run { self.appState = .error(error.localizedDescription) }
                Log.error("세션 로그아웃 실패: \(error.localizedDescription)", tag: "Session")
            }
        }
    }

    func deleteAccount() {
        loadingMessage = "계정을 삭제하는 중입니다..."
        appState = .loading
        isRestoringSession = true
        Log.info("세션 계정 삭제 플로우 시작", tag: "Session")
        Task {
            do {
                try await authUseCase.deleteAccount()
                await MainActor.run {
                    self.currentUser = nil
                    self.pets = []
                    self.petUseCase.clearAllPets()
                    self.appState = .default
                    self.flow = .login
                    self.isRestoringSession = false
                }
                Log.info("세션 계정 삭제 성공", tag: "Session")
            } catch {
                await MainActor.run {
                    self.appState = .error(error.localizedDescription)
                    self.isRestoringSession = false
                }
                Log.error("세션 계정 삭제 실패: \(error.localizedDescription)", tag: "Session")
            }
        }
    }

    func addPet(_ pet: Pet) {
        petUseCase.addPet(pet)
    }

    func updatePet(_ pet: Pet) {
        petUseCase.updatePet(pet)
    }

    func removePet(with id: UUID) {
        petUseCase.removePet(with: id)
    }

    func clearPets() {
        petUseCase.clearAllPets()
    }

    func resetState() {
        appState = .default
        Log.debug("세션 상태 초기화", tag: "Session")
    }

    private func restoreSession() {
        Task {
            Log.info("세션 복원 시도 - Firebase 토큰 검증", tag: "Session")
            await MainActor.run {
                self.loadingMessage = "세션을 확인하고 있어요..."
                self.flow = .splash
                self.appState = .loading
                self.isRestoringSession = true
            }

            do {
                let restoredUser = try await authUseCase.restoreSession()
                await MainActor.run {
                    self.appState = .default
                    self.isRestoringSession = false
                    self.updateFlow(for: restoredUser ?? self.currentUser)
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.appState = .error(error.localizedDescription)
                    self.isRestoringSession = false
                    self.updateFlow(for: nil)
                }
            }
        }
    }

    private func updateFlow(for user: User?) {
        flow = user == nil ? .login : .main
    }
}
