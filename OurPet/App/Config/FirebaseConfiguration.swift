//
//  FirebaseConfiguration.swift
//  OurPet
//
//  Created by Assistant on 10/28/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth

enum FirebaseConfiguration {
    static func configureIfNeeded() {
        if FirebaseApp.app() != nil { return }

        let environment = AppEnvironment.current
        let plistFileName = "GoogleService-Info-\(environment.rawValue)"
        let bundle = Bundle.main

        // 1) 번들에서 plist 우선 시도
        if let url = bundle.url(forResource: plistFileName, withExtension: "plist") ??
            bundle.url(forResource: plistFileName, withExtension: "plist", subdirectory: "Resources/Secrets/\(environment.rawValue)"),
           let options = FirebaseOptions(contentsOfFile: url.path) {
            Log.info("Firebase 설정 사용(plist): env=\(environment.rawValue), file=\(url.lastPathComponent)", tag: "Firebase")
            FirebaseApp.configure(options: options)
            return
        }

        // 2) 없으면 환경별 옵션 직접 구성
        let options: FirebaseOptions
        switch environment {
        case .dev:
            options = FirebaseOptions(googleAppID: "1:297186358659:ios:b1347b4e213b82fbeeb2b6", gcmSenderID: "297186358659")
            options.apiKey = "AIzaSyAb2kftlm_WKfQliPkOnBT9TWkfXmT3alQ"
            options.projectID = "ourpet-app"
            options.storageBucket = "ourpet-app.firebasestorage.app"
        case .live:
            options = FirebaseOptions(googleAppID: "1:297186358659:ios:9e4553aad1217f32eeb2b6", gcmSenderID: "297186358659")
            options.apiKey = "AIzaSyAb2kftlm_WKfQliPkOnBT9TWkfXmT3alQ"
            options.projectID = "ourpet-app"
            options.storageBucket = "ourpet-app.firebasestorage.app"
        }
        let maskedKey: String = {
            guard let key = options.apiKey else { return "nil" }
            return String(key.suffix(6))
        }()
        Log.info("Firebase 설정 사용(code): env=\(environment.rawValue), appID=\(options.googleAppID), apiKey(끝6)=\(maskedKey)", tag: "Firebase")
        FirebaseApp.configure(options: options)
        
        // Firebase Analytics 환경별 설정
        if environment.analyticsEnabled {
            Log.info("Firebase Analytics 활성화: \(environment.rawValue)", tag: "Firebase")
        } else {
            Log.info("Firebase Analytics 비활성화: \(environment.rawValue)", tag: "Firebase")
        }
    }
}



