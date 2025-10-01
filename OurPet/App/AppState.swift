//
//  AppState.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

enum AppState: Equatable {
    case `default`
    case loading
    case error(String)
}

enum AppAlertKind {
    case generic
    case retryable(() -> Void)
}

struct AppAlert: Identifiable {
    let id = UUID()
    let message: String
    let kind: AppAlertKind
}
