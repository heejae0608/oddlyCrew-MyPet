import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var session: SessionViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.blue)

            Text("MyPet")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(session.loadingMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}
