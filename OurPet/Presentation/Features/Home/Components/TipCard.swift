import SwiftUI

struct TipCard: View {
    let tip: DailyTip

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: tip.icon)
                .font(.system(size: 28))
                .foregroundColor(AppColor.orange)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppColor.orange.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .appFont(15, weight: .semibold)
                    .foregroundColor(AppColor.cardDetailValue)
                Text(tip.message)
                    .appFont(13)
                    .foregroundColor(AppColor.cardDetailLabel)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.tipCardBackground)
        )
        .shadow(color: AppColor.shadowSoft, radius: 10, x: 0, y: 6)
    }
}
