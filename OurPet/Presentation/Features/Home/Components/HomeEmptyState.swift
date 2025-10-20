import SwiftUI

struct HomeEmptyState: View {
    let onRegisterTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(AppColor.orange.opacity(0.5))

            Text("먼저 반려동물을 등록해 주세요")
                .appFont(20, weight: .semibold)

            Text("등록된 펫이 없어요. 새로운 친구를 추가하면 개별 프로필과 건강 정보를 한눈에 볼 수 있습니다.")
                .appFont(15)
                .foregroundStyle(AppColor.subText)
                .multilineTextAlignment(.center)

            Button(action: onRegisterTap) {
                Text("반려동물 등록")
                    .appFont(17, weight: .semibold)
                    .foregroundStyle(AppColor.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppColor.orange)
                    .cornerRadius(20)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColor.white)
                .shadow(color: AppColor.shadowSoft, radius: 16, x: 0, y: 12)
        )
    }
}
