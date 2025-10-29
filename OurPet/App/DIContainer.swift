//
//  DIContainer.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI

final class DIContainer {
    static let shared = DIContainer()

    private let userRepository: UserRepositoryInterface
    private let petRepository: PetRepositoryInterface
    private let conversationRepository: ConversationRepositoryInterface
    private let chatConversationRepository: ChatConversationRepositoryInterface
    private let chatService: ChatGPTServicing
    private let firebaseAuthService: FirebaseAuthServiceProtocol
    private let remoteUserDataSource: RemoteUserDataSource
    private let remotePetDataSource: RemotePetDataSourceInterface
    private let remoteConversationDataSource: RemoteConversationDataSourceInterface
    private let remoteChatConversationDataSource: RemoteChatConversationDataSourceInterface
    private let remoteAppConfigDataSource: RemoteAppConfigDataSourceInterface
    private let appConfigRepository: AppConfigRepositoryInterface

    init(
        userRepository: UserRepositoryInterface? = nil,
        petRepository: PetRepositoryInterface? = nil,
        conversationRepository: ConversationRepositoryInterface? = nil,
        chatConversationRepository: ChatConversationRepositoryInterface? = nil,
        chatService: ChatGPTServicing = ChatGPTService(),
        firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService(),
        remoteUserDataSource: RemoteUserDataSource = FirestoreUserDataSource(),
        remotePetDataSource: RemotePetDataSourceInterface = RemotePetDataSource(),
        remoteConversationDataSource: RemoteConversationDataSourceInterface = RemoteConversationDataSource(),
        remoteChatConversationDataSource: RemoteChatConversationDataSourceInterface = RemoteChatConversationDataSource(),
        remoteAppConfigDataSource: RemoteAppConfigDataSourceInterface = RemoteAppConfigDataSource(),
        appConfigRepository: AppConfigRepositoryInterface? = nil
    ) {
        self.userRepository = userRepository ?? UserRepository()
        self.remotePetDataSource = remotePetDataSource
        self.remoteConversationDataSource = remoteConversationDataSource
        self.remoteChatConversationDataSource = remoteChatConversationDataSource
        self.petRepository = petRepository ?? PetRepository(remotePetDataSource: remotePetDataSource)
        self.conversationRepository = conversationRepository ?? ConversationRepository(remoteConversationDataSource: remoteConversationDataSource)
        self.chatConversationRepository = chatConversationRepository ?? ChatConversationRepository(remoteDataSource: remoteChatConversationDataSource)
        self.chatService = chatService
        self.firebaseAuthService = firebaseAuthService
        self.remoteUserDataSource = remoteUserDataSource
        self.remoteAppConfigDataSource = remoteAppConfigDataSource
        self.appConfigRepository = appConfigRepository ?? AppConfigRepository(remoteDataSource: remoteAppConfigDataSource)
    }

    // MARK: - UseCases

    func makeAuthUseCase() -> AuthUseCaseInterface {
        AuthUseCase(
            userRepository: userRepository,
            petRepository: petRepository,
            conversationRepository: conversationRepository,
            chatConversationRepository: chatConversationRepository,
            firebaseAuthService: firebaseAuthService,
            remoteUserDataSource: remoteUserDataSource
        )
    }

    func makePetUseCase() -> PetUseCaseInterface {
        PetUseCase(
            userRepository: userRepository,
            petRepository: petRepository
        )
    }

    func makeChatUseCase() -> ChatUseCaseInterface {
        ChatUseCase(
            userRepository: userRepository,
            petRepository: petRepository,
            conversationRepository: conversationRepository,
            chatConversationRepository: chatConversationRepository,
            chatService: chatService
        )
    }

    func makeAppConfigUseCase() -> AppConfigUseCaseInterface {
        AppConfigUseCase(repository: appConfigRepository)
    }

    // MARK: - ViewModels

    @MainActor func makeSessionViewModel() -> SessionViewModel {
        SessionViewModel(
            authUseCase: makeAuthUseCase(),
            petUseCase: makePetUseCase(),
            petRepository: petRepository
        )
    }

    @MainActor func makeChatViewModel(session: SessionViewModel) -> ChatViewModel {
        ChatViewModel(session: session, chatUseCase: makeChatUseCase())
    }

    @MainActor func makeHistoryViewModel(session: SessionViewModel) -> HistoryViewModel {
        HistoryViewModel(
            session: session,
            chatUseCase: makeChatUseCase(),
            conversationRepository: conversationRepository,
            chatConversationRepository: chatConversationRepository
        )
    }

    @MainActor func makeSettingsViewModel(session: SessionViewModel) -> SettingsViewModel {
        SettingsViewModel(
            session: session,
            conversationRepository: conversationRepository,
            chatConversationRepository: chatConversationRepository
        )
    }
}

// MARK: - EnvironmentKey

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
