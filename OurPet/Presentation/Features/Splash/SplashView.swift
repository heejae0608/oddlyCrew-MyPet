import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var session: SessionViewModel
    @State private var didRequestTracking = false

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
                session.markTrackingPermissionResolved()
            }
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
