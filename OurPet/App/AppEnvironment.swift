//
//  AppEnvironment.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

enum AppEnvironment: String {
    case dev
    case live

    static let current: AppEnvironment = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return .live
        }
        if bundleIdentifier.hasSuffix(".dev") {
            return .dev
        }
        return .live
    }()

    var collectionPrefix: String {
        switch self {
        case .dev:
            return "dev-"
        case .live:
            return "live-"
        }
    }

    func collectionName(for baseName: String) -> String {
        "\(collectionPrefix)\(baseName)"
    }

    // Firebase Analytics 설정
    var analyticsEnabled: Bool {
        switch self {
        case .dev:
            return false // DEV는 분석 비활성화
        case .live:
            return true  // LIVE만 분석 활성화
        }
    }

    func printEnvironmentInfo() {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        Log.info("현재 환경: \(rawValue.uppercased()) | BundleID: \(bundleId)", tag: "Env")
    }
}
