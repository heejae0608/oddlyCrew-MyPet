//
//  AppConfigUseCase.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

protocol AppConfigUseCaseInterface {
    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo?
    func fetchNotice() async throws -> AppNotice?
}

final class AppConfigUseCase: AppConfigUseCaseInterface {
    private let repository: AppConfigRepositoryInterface

    init(repository: AppConfigRepositoryInterface) {
        self.repository = repository
    }

    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo? {
        try await repository.fetchForceUpdateInfo()
    }

    func fetchNotice() async throws -> AppNotice? {
        try await repository.fetchNotice()
    }
}
