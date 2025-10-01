import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var session: SessionViewModel

    var body: some View {
        ZStack {
            AppColor.orange
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 88))
                    .foregroundColor(.white)

                Text("OurPet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text(session.loadingMessage)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(40)
        }
    }
}
