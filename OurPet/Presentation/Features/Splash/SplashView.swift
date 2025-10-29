import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.openURL) private var openURL
    @StateObject private var startupViewModel = SplashStartupViewModel()
    @State private var didRequestTracking = false
    @State private var hasStartedStartupChecks = false
    @State private var didCompleteStartupFlow = false

    var body: some View {
        ZStack {
            AppColor.orange
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Image("OurPetLogo")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 140, height: 140)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("OurPet")
                    .appFont(32, weight: .bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text(session.loadingMessage)
                        .appFont(13, weight: .semibold)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(40)
            overlayContent
        }
        .onAppear {
            // 스플래시 화면 진입 이벤트 (한 번만)
            if !didRequestTracking {
                AnalyticsHelper.logScreenView("SplashView")
                AnalyticsHelper.logEvent("app_start", parameters: [
                    "environment": AppEnvironment.current.rawValue,
                    "bundle_id": Bundle.main.bundleIdentifier ?? "unknown"
                ])
            }
            
            guard didRequestTracking == false else { 
                print("🔍 ATT 권한 요청 이미 완료됨")
                return 
            }
            didRequestTracking = true
            print("🔍 SplashView에서 ATT 권한 요청 시작")
            print("🔍 AdMobManager.shared 인스턴스: \(AdMobManager.shared)")
            AdMobManager.shared.prepareForLaunchAds {
                print("🔍 SplashView에서 ATT 권한 요청 완료 콜백")
                startStartupChecksIfNeeded()
            }
        }
        .onChange(of: startupViewModel.forceUpdateInfo) { info in
            guard let info else { return }
            session.loadingMessage = info.title
        }
        .onChange(of: startupViewModel.notice) { notice in
            guard let notice else { return }
            session.loadingMessage = notice.allowUsageDuringNotice
            ? "공지사항을 확인해주세요."
            : "현재 공지로 인해 이용이 제한됩니다."
        }
        .onChange(of: startupViewModel.isCompleted) { completed in
            guard completed, didCompleteStartupFlow == false else { return }
            didCompleteStartupFlow = true
            session.loadingMessage = "잠시만 기다려주세요..."
            session.markTrackingPermissionResolved()
        }
    }

    private var overlayContent: some View {
        Group {
            if let info = startupViewModel.forceUpdateInfo {
                ForceUpdateOverlay(
                    info: info,
                    onUpdate: { openStoreAndTerminate(for: info) }
                )
            } else if let notice = startupViewModel.notice {
                NoticeOverlay(
                    notice: notice,
                    onConfirm: { handleNoticeConfirm(notice) }
                )
            }
        }
    }

    private func startStartupChecksIfNeeded() {
        guard hasStartedStartupChecks == false else { return }
        hasStartedStartupChecks = true
        session.loadingMessage = "앱 정보를 확인하고 있어요..."

        Task {
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            await startupViewModel.evaluateStartupChecks(currentVersion: currentVersion)
        }
    }

    private func openStoreAndTerminate(for info: ForceUpdateInfo) {
        guard let url = info.storeURL else {
            Log.error("스토어 URL이 설정되어 있지 않아 강제 업데이트를 진행할 수 없습니다.", tag: "Splash")
            terminateApp()
            return
        }
        openURL(url)
        terminateApp()
    }

    private func handleNoticeConfirm(_ notice: AppNotice) {
        if notice.allowUsageDuringNotice {
            startupViewModel.acknowledgeNotice()
        } else {
            terminateApp()
        }
    }

    private func terminateApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            exit(0)
        }
    }
}

private struct ForceUpdateOverlay: View {
    let info: ForceUpdateInfo
    let onUpdate: () -> Void

    var body: some View {
        Color.black.opacity(0.65)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    Text(info.title)
                        .appFont(22, weight: .bold)
                        .multilineTextAlignment(.center)

                    Text(info.message)
                        .appFont(15, weight: .medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button(action: onUpdate) {
                        Text("업데이트 하기")
                            .appFont(16, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 24)
            }
    }
}

private struct NoticeOverlay: View {
    let notice: AppNotice
    let onConfirm: () -> Void

    var body: some View {
        Color.black.opacity(0.55)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 18) {
                    Text(notice.title)
                        .appFont(20, weight: .bold)
                        .multilineTextAlignment(.center)

                    Text(notice.message)
                        .appFont(15, weight: .medium)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: onConfirm) {
                        Text("확인")
                            .appFont(15, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 24)
            }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        SplashView()
            .environmentObject(PreviewSessionFactory.makeSession())
    }
}
#endif
