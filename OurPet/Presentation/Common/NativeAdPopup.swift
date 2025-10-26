import SwiftUI
import GoogleMobileAds

@MainActor
final class NativeAdLoader: NSObject, ObservableObject, @MainActor NativeAdLoaderDelegate, @MainActor NativeAdDelegate {
    static let shared = NativeAdLoader()

    @Published var nativeAd: NativeAd?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: Error?
    @Published private(set) var shouldShowAd = false

    private var adLoader: AdLoader?
    private var currentPlacement: NativeAdPlacement?

    private override init() {
        super.init()
    }

    func load(for placement: NativeAdPlacement) {
        nativeAd = nil
        loadError = nil
        isLoading = true
        shouldShowAd = false
        adLoader?.delegate = nil
        adLoader = nil
        currentPlacement = placement

        let options = NativeAdViewAdOptions()
        let multipleOptions = MultipleAdsAdLoaderOptions()
        multipleOptions.numberOfAds = 1

        adLoader = AdLoader(
            adUnitID: AdMobIDs.nativePopupUnitID(for: placement),
            rootViewController: topViewController(),
            adTypes: [.native],
            options: [options, multipleOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }

    func reload() {
        guard let placement = currentPlacement else { return }
        load(for: placement)
    }

    func clear() {
        nativeAd = nil
        loadError = nil
        isLoading = false
        shouldShowAd = false
        adLoader?.delegate = nil
        adLoader = nil
        currentPlacement = nil
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.topMostViewController()
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        isLoading = false
        loadError = nil
        shouldShowAd = true
        Log.debug("네이티브 광고 로드 완료", tag: "AdMob")
    }

    @MainActor func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Log.error("네이티브 광고 로드 실패: \(error.localizedDescription)", tag: "AdMob")
        nativeAd = nil
        loadError = error
        isLoading = false
        shouldShowAd = false
    }

    @MainActor func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        Log.debug("네이티브 광고 클릭", tag: "AdMob")
    }

    @MainActor func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        Log.debug("네이티브 광고 노출", tag: "AdMob")
    }
}

struct NativeAdHostedView: UIViewRepresentable {
    let ad: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView(frame: .zero)
        adView.backgroundColor = .clear

        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.layer.cornerRadius = 12
        mediaView.clipsToBounds = true

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 18)
        headlineLabel.numberOfLines = 2

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.numberOfLines = 3

        let callToActionButton = UIButton(type: .system)
        callToActionButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        callToActionButton.backgroundColor = UIColor(AppColor.orange)
        callToActionButton.tintColor = .white
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.layer.masksToBounds = true
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        callToActionButton.isUserInteractionEnabled = false

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let advertiserLabel = UILabel()
        advertiserLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        advertiserLabel.textColor = UIColor.secondaryLabel
        advertiserLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel, callToActionButton])
        textStack.axis = .vertical
        textStack.spacing = 8

        let horizontalStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 12
        horizontalStack.alignment = .center

        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false

        let headerStack = UIStackView(arrangedSubviews: [UILabel.adBadgeLabel(), UIView(), adChoicesView])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8

        let rootStack = UIStackView(arrangedSubviews: [headerStack, mediaView, horizontalStack, advertiserLabel])
        rootStack.axis = .vertical
        rootStack.spacing = 12

        adView.addSubview(rootStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            rootStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            rootStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            rootStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            adChoicesView.widthAnchor.constraint(lessThanOrEqualToConstant: 40),
            adChoicesView.heightAnchor.constraint(lessThanOrEqualToConstant: 20)
        ])

        adView.mediaView = mediaView
        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.callToActionView = callToActionButton
        adView.iconView = iconImageView
        adView.adChoicesView = adChoicesView
        adView.advertiserView = advertiserLabel

        (headlineLabel).text = ad.headline
        (bodyLabel).text = ad.body
        callToActionButton.setTitle(ad.callToAction, for: .normal)

        if let icon = ad.icon?.image {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        if let advertiser = ad.advertiser {
            advertiserLabel.text = "제공: \(advertiser)"
            advertiserLabel.isHidden = false
        } else {
            advertiserLabel.isHidden = true
        }

        adView.nativeAd = ad
        return adView
    }

    func updateUIView(_ uiView: NativeAdView, context: Context) { }
}

struct NativeAdPopupView: View {
    @ObservedObject var loader: NativeAdLoader
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 12)

                    Group {
                        if let ad = loader.nativeAd {
                            NativeAdHostedView(ad: ad)
                                .padding(18)
                                .background(Color(.systemBackground))
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 12)
                        } else if loader.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text("광고를 불러오고 있어요…")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            .padding(32)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 12) {
                                Text("광고를 불러오지 못했어요")
                                    .font(.system(size: 15, weight: .medium))
                        Button("다시 시도") { loader.reload() }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                        }
                    }
                    .frame(maxWidth: 360)
                    .frame(maxHeight: geometry.size.height * (2.0 / 3.0))
                }
                .padding(.horizontal, 24)
            }
            .transition(.opacity.combined(with: .scale))
        }
    }

    private func dismiss() {
        isPresented = false
        loader.clear()
    }
}

private extension UILabel {
    static func adBadgeLabel() -> UILabel {
        let label = UILabel()
        label.text = "광고"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(AppColor.orange)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        label.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return label
    }
}
