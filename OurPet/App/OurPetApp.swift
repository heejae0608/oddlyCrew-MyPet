//
//  OurPetApp.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import FirebaseCore
import SwiftUI

@main
struct OurPetApp: App {
    private let container = DIContainer.shared
    @StateObject private var sessionViewModel = DIContainer.shared.makeSessionViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didRequestTrackingAuthorization = false

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Log.info("FirebaseApp configure() 수행", tag: "App")
        } else {
            Log.debug("FirebaseApp 이미 초기화됨", tag: "App")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, container)
                .environmentObject(sessionViewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active, didRequestTrackingAuthorization == false else { return }
            didRequestTrackingAuthorization = true
            AdMobManager.shared.configureIfNeeded()
        }
    }
}
