//
//  HistoryAdBannerRow.swift
//  OurPet
//
//  Created by 전희재 on 10/21/25.
//

import SwiftUI

struct HistoryAdBannerRow: View {
  var body: some View {
    VStack(spacing: 0) {
      Divider()
        .background(AppColor.divider)

      AdMobBannerView(adUnitID: AdMobIDs.historyBannerUnitID)
        .frame(minHeight: 50, idealHeight: 70, maxHeight: 90)
        .frame(maxWidth: .infinity)
        .background(AppColor.surfaceBackground)
        .padding(.vertical, 4)
    }
  }
}
