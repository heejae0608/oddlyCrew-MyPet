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
                    .foregroundStyle(AppColor.white)
                    .padding(.bottom, -15)

                Text("OurPet")
                    .appFont(32, weight: .bold)
                    .foregroundStyle(AppColor.white)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppColor.white)
                    Text(session.loadingMessage)
                        .appFont(13, weight: .semibold)
                        .foregroundStyle(AppColor.white.opacity(0.85))
                }
            }
            .padding(40)
        }
        .onAppear {
            guard didRequestTracking == false else { return }
            didRequestTracking = true
            AdMobManager.shared.prepareForLaunchAds {
                session.markTrackingPermissionResolved()
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        SplashView()
            .environmentObject(PreviewSessionFactory.makeSession())
    }
}
