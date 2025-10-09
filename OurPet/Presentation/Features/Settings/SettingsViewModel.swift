//
//  SettingsViewModel.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    private let session: SessionViewModel
    private let conversationRepository: ConversationRepositoryInterface
    private let chatConversationRepository: ChatConversationRepositoryInterface

    @Published private(set) var consultationCount: Int = 0

    let developerEmail = "oddlycrew@gmail.com"
    let appStoreURL = URL(string: "https://apps.apple.com/kr/app/ourpet/id0000000000")

    let openSourceLicenses: [OpenSourceLicense] = [
        .init(
            name: "Firebase iOS SDK",
            license: "Apache License 2.0",
            url: URL(string: "https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE")
        ),
        .init(
            name: "Moya",
            license: "MIT License",
            url: URL(string: "https://github.com/Moya/Moya/blob/master/License.md")
        ),
        .init(
            name: "Alamofire",
            license: "MIT License",
            url: URL(string: "https://github.com/Alamofire/Alamofire/blob/master/LICENSE")
        ),
        .init(
            name: "RxSwift",
            license: "MIT License",
            url: URL(string: "https://github.com/ReactiveX/RxSwift/blob/main/LICENSE.md")
        ),
        .init(
            name: "ReactiveSwift",
            license: "MIT License",
            url: URL(string: "https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/LICENSE.md")
        ),
        .init(
            name: "SwiftProtobuf",
            license: "Apache License 2.0",
            url: URL(string: "https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt")
        ),
        .init(
            name: "Google Utilities",
            license: "Apache License 2.0",
            url: URL(string: "https://github.com/google/GoogleUtilities/blob/main/LICENSE")
        ),
        .init(
            name: "Nanopb",
            license: "zlib License",
            url: URL(string: "https://github.com/nanopb/nanopb/blob/master/LICENSE.txt")
        )
    ]

    init(
        session: SessionViewModel,
        conversationRepository: ConversationRepositoryInterface,
        chatConversationRepository: ChatConversationRepositoryInterface
    ) {
        self.session = session
        self.conversationRepository = conversationRepository
        self.chatConversationRepository = chatConversationRepository
    }

    var user: User? {
        session.currentUser
    }

    func logout() {
        session.logout()
    }

    func deleteAccount() {
        session.deleteAccount()
    }

    func refreshConsultationCount(pets: [Pet]) async {
        guard pets.isEmpty == false else {
            consultationCount = 0
            return
        }

        var chatConversationIds = Set<UUID>()
        var legacyResponseIds = Set<String>()

        for pet in pets {
            do {
                let chatConversations = try await chatConversationRepository.getConversations(for: pet.id)
                chatConversationIds.formUnion(chatConversations.map { $0.id })
            } catch {
                Log.warning("채팅 상담 기록 조회 실패 (petId: \(pet.id.uuidString)): \(error.localizedDescription)", tag: "SettingsViewModel")
            }

            do {
                let legacyConversations = try await conversationRepository.getConversations(for: pet.id)
                legacyResponseIds.formUnion(legacyConversations.map { $0.responseId })
            } catch {
                Log.warning("레거시 상담 기록 조회 실패 (petId: \(pet.id.uuidString)): \(error.localizedDescription)", tag: "SettingsViewModel")
            }
        }

        let total = chatConversationIds.count + legacyResponseIds.count
        consultationCount = total
    }
}
