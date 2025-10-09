import SwiftUI

struct OpenSourceLicense: Identifiable {
    let id = UUID()
    let name: String
    let license: String
    let url: URL?
}

struct OpenSourceLicensesView: View {
    let licenses: [OpenSourceLicense]

    var body: some View {
        List(licenses) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)

                Text(item.license)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let url = item.url {
                    Link(destination: url) {
                        Label("라이선스 전문 보기", systemImage: "arrow.up.right.square")
                            .font(.footnote)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("오픈소스 라이선스")
    }
}

#if DEBUG
struct OpenSourceLicensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OpenSourceLicensesView(licenses: [
                OpenSourceLicense(
                    name: "Firebase iOS SDK",
                    license: "Apache License 2.0",
                    url: URL(string: "https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE")
                ),
                OpenSourceLicense(
                    name: "Moya",
                    license: "MIT License",
                    url: URL(string: "https://github.com/Moya/Moya/blob/master/License.md")
                )
            ])
        }
    }
}
#endif
