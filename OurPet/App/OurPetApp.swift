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
    private let container: DIContainer
    @StateObject private var sessionViewModel: SessionViewModel

    init() {
        // Firebase 초기화
        FirebaseConfiguration.configureIfNeeded()
        
        // 환경 정보 출력
        AppEnvironment.current.printEnvironmentInfo()

        // Firebase 초기화 이후 DI 구성 요소 생성 (의존성에서 Firestore 접근 가능하도록)
        self.container = DIContainer.shared
        self._sessionViewModel = StateObject(wrappedValue: DIContainer.shared.makeSessionViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.diContainer, container)
                .environmentObject(sessionViewModel)
        }
    }
}
