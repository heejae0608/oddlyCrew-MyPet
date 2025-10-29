//
//  OurPetApp.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import FirebaseCore
import FirebaseAuth
import UIKit
import SwiftUI

@main
struct OurPetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let container: DIContainer
    @StateObject private var sessionViewModel: SessionViewModel

    init() {
        FirebaseConfiguration.configureIfNeeded()
        
        // 환경 정보 출력
        AppEnvironment.current.printEnvironmentInfo()

        // 환경 전환(dev<->live) 감지 시, 인증 상태 초기화하여 교차 자동로그인 방지
        let currentEnv = AppEnvironment.current.rawValue
        let lastEnv = UserDefaults.standard.string(forKey: "lastEnvironment")
        if lastEnv != currentEnv {
            _ = try? Auth.auth().signOut()
            UserDefaults.standard.set(currentEnv, forKey: "lastEnvironment")
            Log.info("환경 전환 감지로 인증 상태 초기화: \(lastEnv ?? "nil") -> \(currentEnv)", tag: "Env")
        }

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
