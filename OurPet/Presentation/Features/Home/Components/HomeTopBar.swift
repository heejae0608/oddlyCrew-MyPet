import SwiftUI

struct HomeTopBar: View {
    let topInset: CGFloat
    let hasPets: Bool
    let onAddTap: () -> Void
    let onReorderTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("OurPet")
                .appFont(24, weight: .bold)
                .foregroundColor(AppColor.ink)

            Spacer(minLength: 0)

            if hasPets {
                HomeTopBarButton(
                    icon: "arrow.up.arrow.down",
                    foreground: Color.primary,
                    background: Color(uiColor: .secondarySystemBackground),
                    action: onReorderTap
                )
            }

            HomeTopBarButton(
                icon: "plus",
                foreground: AppColor.white,
                background: AppColor.orange,
                action: onAddTap
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, topInset + 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.lightGray)
    }
}

private struct HomeTopBarButton: View {
    let icon: String
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .foregroundColor(foreground)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(background)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
