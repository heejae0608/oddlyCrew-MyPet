//
//  AppConfigRepositoryInterface.swift
//  OurPet
//
//  Created by Codex on 10/29/24.
//

import Foundation

protocol AppConfigRepositoryInterface {
    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo?
    func fetchNotice() async throws -> AppNotice?
}
