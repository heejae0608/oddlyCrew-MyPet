//
//  AppNotice.swift
//  OurPet
//
//  Created by Codex on 10/29/24.
//

import Foundation

struct AppNotice: Equatable {
    let title: String
    let message: String
    let isEnabled: Bool
    let allowUsageDuringNotice: Bool
}
