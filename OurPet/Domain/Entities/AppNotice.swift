//
//  AppNotice.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

struct AppNotice: Equatable {
    let title: String
    let message: String
    let isEnabled: Bool
    let allowUsageDuringNotice: Bool
}
