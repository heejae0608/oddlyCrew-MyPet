//
//  SplashStartupViewModel.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

@MainActor
final class SplashStartupViewModel: ObservableObject {
    @Published private(set) var forceUpdateInfo: ForceUpdateInfo?
    @Published private(set) var notice: AppNotice?
    @Published private(set) var isEvaluating = false
    @Published private(set) var isCompleted = false

    private let appConfigUseCase: AppConfigUseCaseInterface

    init(appConfigUseCase: AppConfigUseCaseInterface = DIContainer.shared.makeAppConfigUseCase()) {
        self.appConfigUseCase = appConfigUseCase
    }

    func evaluateStartupChecks(currentVersion: String) async {
        guard isEvaluating == false, isCompleted == false else { return }
        isEvaluating = true

        do {
            if let forceUpdate = try await appConfigUseCase.fetchForceUpdateInfo(),
               forceUpdate.requiresUpdate(currentVersion: currentVersion) {
                forceUpdateInfo = forceUpdate
                isEvaluating = false
                return
            }

            if let notice = try await appConfigUseCase.fetchNotice(),
               notice.isEnabled {
                self.notice = notice
                isEvaluating = false
                if notice.allowUsageDuringNotice == false {
                    Log.info("공지사항으로 앱 사용 제한 - 타이틀: \(notice.title)", tag: "Splash")
                }
                return
            }

            completeChecks()
        } catch {
            Log.error("시작 체크 실패: \(error.localizedDescription)", tag: "Splash")
            completeChecks()
        }
    }

    func acknowledgeNotice() {
        guard let notice else { return }
        if notice.allowUsageDuringNotice {
            self.notice = nil
            completeChecks()
        }
    }

    func dismissForceUpdateBanner() {
        // 강제 업데이트는 앱을 막아야 하므로 처리하지 않음
    }

    private func completeChecks() {
        isEvaluating = false
        isCompleted = true
    }
}
