import SwiftUI
import UIKit

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false
    var fontWeight: Font.Weight = .regular

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .appFont(16, weight: fontWeight)
                    .foregroundStyle(AppColor.placeholderText)
                    .padding(contentPadding)
            }

            TextField("", text: $text)
                .appFont(16, weight: fontWeight)
                .foregroundStyle(AppColor.text)
                .padding(contentPadding)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(disableAutocorrection)
                .textContentType(textContentType)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColor.inputSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.inputBorder)
        )
    }

    private var contentPadding: EdgeInsets {
        EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }
}

#if DEBUG
struct AppTextField_Previews: PreviewProvider {
    private struct PreviewWrapper: View {
        @State private var empty: String = ""
        @State private var filled: String = "초코"

        var body: some View {
            VStack(spacing: 20) {
                AppTextField(placeholder: "이름", text: $empty)
                AppTextField(placeholder: "이름", text: $filled)
            }
            .padding()
            .background(AppColor.formBackground)
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
#endif
