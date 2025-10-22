//
//  AdMobBannerView.swift
//  OurPet
//
//  Created by 전희재 on 2/19/25.
//

import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: UIViewControllerRepresentable {
  let adUnitID: String

  func makeUIViewController(context: Context) -> BannerViewController {
    BannerViewController(adUnitID: adUnitID)
  }

  func updateUIViewController(_ uiViewController: BannerViewController, context: Context) {
    uiViewController.update(adUnitID: adUnitID)
  }
}

final class BannerViewController: UIViewController {
  private var adUnitID: String
  private var heightConstraint: NSLayoutConstraint?
  private var widthConstraint: NSLayoutConstraint?
  private var lastRequestedWidth: CGFloat = 0

  private lazy var bannerView: BannerView = {
    let banner = BannerView()
    banner.translatesAutoresizingMaskIntoConstraints = false
    banner.delegate = self
    return banner
  }()

  init(adUnitID: String) {
    self.adUnitID = adUnitID
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.addSubview(bannerView)

    NSLayoutConstraint.activate([
      bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      bannerView.topAnchor.constraint(equalTo: view.topAnchor),
      bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let width = bannerView.widthAnchor.constraint(equalToConstant: 320)
    width.priority = .defaultHigh
    width.isActive = true
    widthConstraint = width

    let height = bannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
    height.priority = .defaultHigh
    height.isActive = true
    heightConstraint = height
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    loadBanner(for: view.bounds.width)
  }

  func update(adUnitID: String) {
    guard self.adUnitID != adUnitID else { return }
    self.adUnitID = adUnitID
    loadBanner(for: view.bounds.width)
  }

  private func loadBanner(for containerWidth: CGFloat) {
    let width = max(containerWidth, 1)
    let targetWidth = max(width, 320)
    let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: targetWidth)
    let widthValue = adaptiveSize.size.width > 0 ? adaptiveSize.size.width : targetWidth
    if abs(widthValue - lastRequestedWidth) < 0.5 {
      return
    }
    lastRequestedWidth = widthValue

    bannerView.adUnitID = adUnitID
    bannerView.rootViewController = self
    bannerView.adSize = adaptiveSize
    let height = adaptiveSize.size.height > 0 ? adaptiveSize.size.height : 50
    heightConstraint?.constant = height
    widthConstraint?.constant = widthValue
    bannerView.load(Request())
  }
}

extension BannerViewController: BannerViewDelegate {
  func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    let adaptiveHeight = bannerView.adSize.size.height
    heightConstraint?.constant = adaptiveHeight > 0 ? adaptiveHeight : 50
    let adaptiveWidth = bannerView.adSize.size.width
    widthConstraint?.constant = adaptiveWidth > 0 ? adaptiveWidth : lastRequestedWidth
  }

  func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
    heightConstraint?.constant = 0
    widthConstraint?.constant = 0
    Log.error("배너 로드 실패: \(error.localizedDescription)", tag: "AdMob")
  }
}
