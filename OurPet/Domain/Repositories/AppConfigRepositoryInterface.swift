//
//  AppConfigRepositoryInterface.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

protocol AppConfigRepositoryInterface {
    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo?
    func fetchNotice() async throws -> AppNotice?
}
