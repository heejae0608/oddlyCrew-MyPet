//
//  AdMobConfiguration.swift
//  OurPet
//
//  Created by 전희재 on 2/19/25.
//

import AppTrackingTransparency
import AdSupport
import Foundation
import UIKit
import GoogleMobileAds

enum NativeAdPlacement {
    case main
    case conversation
}

enum AdMobIDs {
    // 환경별 앱 ID
    static var appID: String {
        switch AppEnvironment.current {
        case .dev:
            return "ca-app-pub-3795485655104320~5990839688"
        case .live:
            return "ca-app-pub-3795485655104320~5990839688"
        }
    }

    // DEV 환경용 광고 단위 ID (테스트 ID 사용)
    static let devConsultationBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let devHistoryBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let devLaunchInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let devNativePopupMainUnitID = "ca-app-pub-3940256099942544/3986624511"
    static let devNativePopupConversationUnitID = "ca-app-pub-3940256099942544/3986624511"

    // LIVE 환경용 광고 단위 ID (실제 광고 ID 사용)
    static let liveConsultationBannerUnitID = "ca-app-pub-3795485655104320/5405991108"
    static let liveHistoryBannerUnitID = "ca-app-pub-3795485655104320/2202911566"
    static let liveLaunchInterstitialUnitID = "ca-app-pub-3795485655104320/7762467804"
    static let liveNativePopupMainUnitID = "ca-app-pub-3795485655104320/6399470582"
    static let liveNativePopupConversationUnitID = "ca-app-pub-3795485655104320/7301488719"

    static var consultationBannerUnitID: String {
        switch AppEnvironment.current {
        case .dev:
            let id = devConsultationBannerUnitID
            Log.debug("AdMob 상담 배너 ID(DEV): \(id)", tag: "AdMob")
            return id
        case .live:
            let id = liveConsultationBannerUnitID
            Log.debug("AdMob 상담 배너 ID(LIVE): \(id)", tag: "AdMob")
            return id
        }
    }

    static var historyBannerUnitID: String {
        switch AppEnvironment.current {
        case .dev:
            let id = devHistoryBannerUnitID
            Log.debug("AdMob 히스토리 배너 ID(DEV): \(id)", tag: "AdMob")
            return id
        case .live:
            let id = liveHistoryBannerUnitID
            Log.debug("AdMob 히스토리 배너 ID(LIVE): \(id)", tag: "AdMob")
            return id
        }
    }

    static var launchInterstitialUnitID: String {
        switch AppEnvironment.current {
        case .dev:
            let id = devLaunchInterstitialUnitID
            Log.debug("AdMob 전면 광고 ID(DEV): \(id)", tag: "AdMob")
            return id
        case .live:
            let id = liveLaunchInterstitialUnitID
            Log.debug("AdMob 전면 광고 ID(LIVE): \(id)", tag: "AdMob")
            return id
        }
    }


    static func nativePopupUnitID(for placement: NativeAdPlacement) -> String {
        switch placement {
        case .main:
            switch AppEnvironment.current {
            case .dev:
                let id = devNativePopupMainUnitID
                Log.debug("AdMob 메인 네이티브 광고 ID(DEV): \(id)", tag: "AdMob")
                return id
            case .live:
                let id = liveNativePopupMainUnitID
                Log.debug("AdMob 메인 네이티브 광고 ID(LIVE): \(id)", tag: "AdMob")
                return id
            }
        case .conversation:
            switch AppEnvironment.current {
            case .dev:
                let id = devNativePopupConversationUnitID
                Log.debug("AdMob 상담 네이티브 광고 ID(DEV): \(id)", tag: "AdMob")
                return id
            case .live:
                let id = liveNativePopupConversationUnitID
                Log.debug("AdMob 상담 네이티브 광고 ID(LIVE): \(id)", tag: "AdMob")
                return id
            }
        }
    }
}

/// Google Mobile Ads SDK 초기화 및 ATT 권한 관리, 전면 광고 로드를 담당한다.
final class AdMobManager: NSObject {
    static let shared = AdMobManager()

    private var hasStarted = false
    private var hasResolvedTrackingPermission = false
    private var isRequestingTrackingPermission = false
    private var trackingCompletionHandlers: [() -> Void] = []
    private var trackingAuthorizationObserver: NSObjectProtocol?

    private var launchInterstitialAd: InterstitialAd?
    private var isLoadingLaunchInterstitial = false
    private var shouldPresentLaunchInterstitial = false
    private var hasPresentedLaunchInterstitial = false


    private override init() {
        super.init()
    }

    /// 스플래시 단계에서 호출하여 ATT 권한 요청 → SDK 초기화 → 전면 광고 로드를 준비한다.
    func prepareForLaunchAds(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            if self.hasResolvedTrackingPermission {
                print("🔍 ATT 권한 이미 해결됨 - 즉시 완료")
                completion()
                return
            }

            self.trackingCompletionHandlers.append(completion)
            guard self.isRequestingTrackingPermission == false else { 
                print("🔍 ATT 권한 요청 중 - 대기열에 추가")
                return 
            }
            self.isRequestingTrackingPermission = true
            print("🔍 ATT 권한 요청 시작")

            self.requestTrackingAuthorization { [weak self] in
                guard let self else { return }
                self.hasResolvedTrackingPermission = true
                self.isRequestingTrackingPermission = false
                self.startSDKIfNeeded()

                let handlers = self.trackingCompletionHandlers
                self.trackingCompletionHandlers.removeAll()
                print("🔍 ATT 권한 요청 완료 - \(handlers.count)개 콜백 실행")
                handlers.forEach { $0() }
            }
        }
    }

    /// 메인 플로우 진입 시 한 번만 호출되어 전면 광고를 보여 준다.
    func presentLaunchAdIfAvailable() {
        DispatchQueue.main.async {
            guard self.hasResolvedTrackingPermission else { return }
            guard self.hasPresentedLaunchInterstitial == false else { return }

            self.shouldPresentLaunchInterstitial = true
            if self.launchInterstitialAd != nil {
                self.presentLaunchInterstitial()
            } else {
                self.loadLaunchInterstitial(force: true)
            }
        }
    }

    private func requestTrackingAuthorization(completion: @escaping () -> Void) {
        print("🔍 requestTrackingAuthorization 메서드 호출됨")
        
        if #available(iOS 14, *) {
            guard UIApplication.shared.applicationState == .active else {
                print("🔍 앱 상태가 active 아님(\(UIApplication.shared.applicationState.rawValue)) - didBecomeActive까지 대기")
                if trackingAuthorizationObserver == nil {
                    trackingAuthorizationObserver = NotificationCenter.default.addObserver(
                        forName: UIApplication.didBecomeActiveNotification,
                        object: nil,
                        queue: .main
                    ) { [weak self] _ in
                        guard let self else { return }
                        if let observer = self.trackingAuthorizationObserver {
                            NotificationCenter.default.removeObserver(observer)
                            self.trackingAuthorizationObserver = nil
                        }
                        print("🔍 앱 활성화됨 - ATT 권한 요청 재시도")
                        self.requestTrackingAuthorization(completion: completion)
                    }
                }
                return
            }

            if let observer = trackingAuthorizationObserver {
                NotificationCenter.default.removeObserver(observer)
                trackingAuthorizationObserver = nil
            }

            let status = ATTrackingManager.trackingAuthorizationStatus
            print("🔍 현재 ATT 상태: \(status.rawValue)")
            print("🔍 iOS 버전: \(UIDevice.current.systemVersion)")
            
            // 상태별 처리
            switch status {
            case .notDetermined:
                print("🔍 ATT 권한 미결정 - 팝업 요청 시작")
                ATTrackingManager.requestTrackingAuthorization { [weak self] newStatus in
                    print("🔍 ATT 팝업 결과: \(newStatus.rawValue)")
                    self?.logAdvertisingIdentifier()
                    DispatchQueue.main.async { completion() }
                }
            case .denied:
                print("🔍 ATT 권한 거부됨")
                logAdvertisingIdentifier()
                DispatchQueue.main.async { completion() }
            case .authorized:
                print("🔍 ATT 권한 허용됨")
                logAdvertisingIdentifier()
                DispatchQueue.main.async { completion() }
            case .restricted:
                print("🔍 ATT 권한 제한됨")
                logAdvertisingIdentifier()
                DispatchQueue.main.async { completion() }
            @unknown default:
                print("🔍 ATT 권한 알 수 없는 상태")
                logAdvertisingIdentifier()
                DispatchQueue.main.async { completion() }
            }
        } else {
            print("🔍 iOS 14 미만 - ATT 권한 불필요")
            logAdvertisingIdentifier()
            DispatchQueue.main.async { completion() }
        }
    }

    private func startSDKIfNeeded() {
        guard hasStarted == false else {
            loadLaunchInterstitial()
            return
        }

        hasStarted = true
        MobileAds.shared.start(completionHandler: { status in
            let adapters = status.adapterStatusesByClassName.keys.joined(separator: ", ")
            Log.debug("GoogleMobileAds SDK 초기화 완료: \(adapters)", tag: "AdMob")
        })
        loadLaunchInterstitial()
    }

    private func loadLaunchInterstitial(force: Bool = false) {
        guard hasPresentedLaunchInterstitial == false else { return }
        guard force || (isLoadingLaunchInterstitial == false && launchInterstitialAd == nil) else { return }

        isLoadingLaunchInterstitial = true
        let unitID = AdMobIDs.launchInterstitialUnitID
        Log.debug("전면 광고 로드 요청: \(unitID)", tag: "AdMob")

        InterstitialAd.load(with: unitID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoadingLaunchInterstitial = false
                if let error {
                    Log.error("전면 광고 로드 실패: \(error.localizedDescription)", tag: "AdMob")
                    return
                }
                guard let ad else { return }
                ad.fullScreenContentDelegate = self
                self.launchInterstitialAd = ad
                Log.debug("전면 광고 로드 완료", tag: "AdMob")

                if self.shouldPresentLaunchInterstitial {
                    self.presentLaunchInterstitial()
                }
            }
        }
    }

    private func presentLaunchInterstitial() {
        guard hasPresentedLaunchInterstitial == false,
              let ad = launchInterstitialAd,
              let rootVC = UIApplication.shared.topMostViewController() else {
            Log.debug("전면 광고 표시 조건 미충족", tag: "AdMob")
            return
        }

        do {
            try ad.canPresent(from: rootVC)
        } catch {
            Log.error("전면 광고 표시 불가: \(error.localizedDescription)", tag: "AdMob")
            launchInterstitialAd = nil
            return
        }

        Log.debug("전면 광고 표시", tag: "AdMob")
        ad.present(from: rootVC)
        hasPresentedLaunchInterstitial = true
        shouldPresentLaunchInterstitial = false
        launchInterstitialAd = nil
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
            Log.info("ATT status: \(statusDescription), IDFA: \(idfa.uuidString)", tag: "AdMob")
        } else {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            Log.info("IDFA(iOS<14): \(idfa.uuidString)", tag: "AdMob")
        }
    }

}

extension AdMobManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        Log.debug("전면 광고 노출", tag: "AdMob")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Log.debug("전면 광고 닫힘", tag: "AdMob")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Log.error("전면 광고 표시 실패: \(error.localizedDescription)", tag: "AdMob")
    }
}

extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController?
        if let base {
            root = base
        } else {
            root = connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        }

        if let nav = root as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }

        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        }

        if let presented = root?.presentedViewController {
            return topMostViewController(base: presented)
        }

        return root
    }
}
