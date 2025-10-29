//
//  ForceUpdateInfo.swift
//  OurPet
//
//  Created by Codex on 10/29/24.
//

import Foundation

struct ForceUpdateInfo: Equatable {
    let minVersion: String
    let title: String
    let message: String
    let isEnabled: Bool
    let storeURL: URL?

    func requiresUpdate(currentVersion: String) -> Bool {
        guard isEnabled else { return false }
        return currentVersion.compareSemanticVersion(to: minVersion) == .orderedAscending
    }
}
