//
//  AppConfigRepository.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

final class AppConfigRepository: AppConfigRepositoryInterface {
    private let remoteDataSource: RemoteAppConfigDataSourceInterface

    init(remoteDataSource: RemoteAppConfigDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo? {
        try await remoteDataSource.fetchForceUpdateInfo()
    }

    func fetchNotice() async throws -> AppNotice? {
        try await remoteDataSource.fetchNotice()
    }
}
