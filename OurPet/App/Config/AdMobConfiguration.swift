//
//  AdMobConfiguration.swift
//  OurPet
//
//  Created by 전희재 on 2/19/25.
//
import AppTrackingTransparency
import AdSupport
import Foundation
import GoogleMobileAds

enum AdMobIDs {
    static let appID = "ca-app-pub-3795485655104320~5990839688"
    static let debugConsultationBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let debugHistoryBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let releaseConsultationBannerUnitID = "ca-app-pub-3795485655104320/5405991108"
    static let releaseHistoryBannerUnitID = "ca-app-pub-3795485655104320/2202911566"

    static var consultationBannerUnitID: String {
        #if DEBUG
        let id = debugConsultationBannerUnitID
        Log.debug("AdMob 상담 배너 ID(디버그): \(id)", tag: "AdMob")
        return id
        #else
        let id = releaseConsultationBannerUnitID
        Log.debug("AdMob 상담 배너 ID(릴리즈): \(id)", tag: "AdMob")
        return id
        #endif
    }

    static var consultationBannerUnitIDValue: String {
        #if DEBUG
        return debugConsultationBannerUnitID
        #else
        return releaseConsultationBannerUnitID
        #endif
    }

    static var historyBannerUnitID: String {
        #if DEBUG
        let id = debugHistoryBannerUnitID
        Log.debug("AdMob 히스토리 배너 ID(디버그): \(id)", tag: "AdMob")
        return id
        #else
        let id = releaseHistoryBannerUnitID
        Log.debug("AdMob 히스토리 배너 ID(릴리즈): \(id)", tag: "AdMob")
        return id
        #endif
    }
}

/// AdMob SDK 초기화 및 ATT 권한 요청을 담당한다.
final class AdMobManager {
    static let shared = AdMobManager()

    private var hasStarted = false
    private init() {}

    func configureIfNeeded() {
        guard hasStarted == false else { return }

        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                DispatchQueue.main.async {
                    ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                        self?.logAdvertisingIdentifier()
                        self?.startSDKIfNeeded()
                    }
                }
            } else {
                logAdvertisingIdentifier()
                startSDKIfNeeded()
            }
        } else {
            logAdvertisingIdentifier()
            startSDKIfNeeded()
        }
    }

    private func startSDKIfNeeded() {
        DispatchQueue.main.async {
            guard self.hasStarted == false else { return }
            self.hasStarted = true
            MobileAds.shared.start(completionHandler: nil)
        }
    }

    private func logAdvertisingIdentifier() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            let statusDescription: String
            switch status {
            case .authorized:
                statusDescription = "authorized"
            case .denied:
                statusDescription = "denied"
            case .restricted:
                statusDescription = "restricted"
            case .notDetermined:
                statusDescription = "notDetermined"
            @unknown default:
                statusDescription = "unknown"
            }

            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            let idfaString = idfa.uuidString
            Log.info("ATT status: \(statusDescription), IDFA: \(idfaString)", tag: "AdMob")
        } else {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            Log.info("IDFA(iOS<14): \(idfa.uuidString)", tag: "AdMob")
        }
    }
}
