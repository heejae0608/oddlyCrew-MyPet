import SwiftUI
import PhotosUI
import UIKit

enum PetFormField: Hashable {
    case name
    case birthDate
    case adoptionDate
    case breed
    case weight
    case existingConditions
}

struct PetProfileForm: View {
    @Binding var data: PetFormData
    var focusedField: FocusState<PetFormField?>.Binding

    var speciesOptions: [String] = PetFormData.speciesOptions
    var genderOptions: [String] = PetFormData.genderOptions

    @State private var photoSelection: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 28) {
            profileSection

            VStack(spacing: 20) {
                SectionContainer(title: "기본 정보") {
                    labeledField("이름") {
                        AppTextField(
                            placeholder: "반려동물 이름을 입력하세요",
                            text: $data.name,
                            autocapitalization: .words,
                            disableAutocorrection: true,
                            fontWeight: .medium
                        )
                        .focused(focusedField, equals: .name)
                        .id(PetFormField.name)
                    }

                    labeledField("태어난 날짜") {
                        AppDateField(
                            placeholder: "태어난 날짜",
                            date: $data.birthDate,
                            focusedField: focusedField,
                            field: .birthDate,
                            minimumDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
                            maximumDate: Date(),
                            fontWeight: .medium
                        )
                    }

                    labeledField("집에 온 날짜") {
                        AppDateField(
                            placeholder: "집에 온 날짜",
                            date: $data.adoptionDate,
                            focusedField: focusedField,
                            field: .adoptionDate,
                            minimumDate: data.birthDate,
                            maximumDate: Date(),
                            fontWeight: .medium
                        )
                    }

                    labeledField("종류") {
                        Picker("종류", selection: $data.species) {
                            ForEach(speciesOptions, id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(AppColor.orange)
                    }

                    labeledField("품종") {
                        AppTextField(
                            placeholder: "품종 (선택사항)",
                            text: $data.breed,
                            autocapitalization: .words,
                            disableAutocorrection: true
                        )
                        .focused(focusedField, equals: .breed)
                        .id(PetFormField.breed)
                    }
                }

                SectionContainer(title: "상세 정보") {
                    labeledField("성별") {
                        Picker("성별", selection: $data.gender) {
                            ForEach(genderOptions, id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(AppColor.orange)
                    }

                    labeledField("중성화 여부") {
                        Toggle(isOn: $data.isNeutered) {
                            Text(data.isNeutered ? "완료" : "미완료")
                                .appFont(16, weight: .medium)
                                .foregroundStyle(AppColor.text)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppColor.orange))
                    }

                    labeledField("몸무게") {
                        AppTextField(
                            placeholder: "몸무게 (kg, 선택사항)",
                            text: $data.weight,
                            keyboardType: .decimalPad,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )
                        .focused(focusedField, equals: .weight)
                        .id(PetFormField.weight)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("기존 질병 / 특이사항")
                            .appFont(14, weight: .semibold)
                            .foregroundStyle(AppColor.text)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppColor.inputSurface)
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppColor.inputBorder)

                            TextEditor(text: $data.existingConditions)
                                .appFont(15)
                                .foregroundStyle(AppColor.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .focused(focusedField, equals: .existingConditions)
                                .id(PetFormField.existingConditions)

                            if data.existingConditions.isEmpty {
                                Text("있다면 입력해주세요 (예: 알러지, 만성 질환 등)")
                                    .appFont(16)
                                    .foregroundStyle(AppColor.placeholderText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 18)
                            }
                        }
                        .frame(minHeight: 140)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onChange(of: photoSelection) { newValue in
            Task {
                guard let newValue else { return }
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.data.setImage(uiImage)
                    }
                }
            }
        }
        .onChange(of: data.birthDate) { newValue in
            if data.adoptionDate < newValue {
                data.adoptionDate = newValue
            }
        }
    }

    private var profileSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColor.profileBadgeBackground)
                    .frame(width: 140, height: 140)

                if let image = data.profileImage.map(Image.init(uiImage:)) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else if let base64 = data.profileImageData,
                          let decoded = Data(base64Encoded: base64),
                          let image = UIImage(data: decoded) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    placeholderImage
                }
            }

            PhotosPicker(selection: $photoSelection, matching: .images) {
                Text(data.profileImage == nil ? "사진 선택" : "사진 변경")
                    .appFont(14, weight: .semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColor.orange)
                    .foregroundStyle(AppColor.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appFont(14, weight: .semibold)
                .foregroundStyle(AppColor.text)

            content()
        }
    }

    private var placeholderImage: some View {
        Image("OurPetLogo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(AppColor.orange)
    }
}

private struct SectionContainer<Content: View>: View {
    let title: String
    private let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .appFont(18, weight: .bold)
                .foregroundStyle(AppColor.text)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.cardSurface)
                .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColor.cardBorder)
        )
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.05)
    }
}

#if DEBUG
private struct PetProfileFormPreviewWrapper: View {
    @State private var data = PetFormData()
    @FocusState private var previewFocus: PetFormField?

    var body: some View {
        ScrollView {
            PetProfileForm(data: $data, focusedField: $previewFocus)
                .padding(.horizontal, 20)
                .padding(.top, 40)
        }
        .background(AppColor.formBackground)
    }
}

struct PetProfileForm_Light_Previews: PreviewProvider {
    static var previews: some View {
        PetProfileFormPreviewWrapper()
            .preferredColorScheme(.light)
    }
}

struct PetProfileForm_Dark_Previews: PreviewProvider {
    static var previews: some View {
        PetProfileFormPreviewWrapper()
            .preferredColorScheme(.dark)
    }
}
#endif
