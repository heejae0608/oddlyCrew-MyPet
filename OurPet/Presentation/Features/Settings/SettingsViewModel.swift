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
    private let chatUseCase: ChatUseCaseInterface

    init(session: SessionViewModel, chatUseCase: ChatUseCaseInterface) {
        self.session = session
        self.chatUseCase = chatUseCase
    }

    var user: User? {
        session.currentUser
    }

    func logout() {
        session.logout()
    }

    func deleteAllData() {
        session.clearPets()
        chatUseCase.clearHistory(for: nil)
    }
}
