//
//  PetRegistrationView.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI

struct PetRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionViewModel

    private let existingPet: Pet?
    @State private var formData: PetFormData
    @FocusState private var focusedField: PetFormField?

    init(pet: Pet? = nil) {
        existingPet = pet
        _formData = State(initialValue: pet.map(PetFormData.init) ?? PetFormData())
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    PetProfileForm(data: $formData, focusedField: $focusedField)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 60)
                }
                .background(AppColor.formBackground.ignoresSafeArea())
                .onChange(of: focusedField) { newValue in
                    guard let newValue else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .navigationTitle(existingPet == nil ? "반려동물 등록" : "반려동물 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.subText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSubmit) {
                        Text(existingPet == nil ? "등록" : "저장")
                            .appFont(16, weight: .semibold)
                            .foregroundStyle(submitTextColor)
                    }
                    .disabled(isSubmitDisabled)
                }
            }
            .tint(AppColor.orange)
        }
    }

    private var isSubmitDisabled: Bool {
        formData.isValid == false
    }

    private var submitTextColor: Color {
        isSubmitDisabled ? AppColor.subText.opacity(0.5) : AppColor.orange
    }

    private func handleSubmit() {
        guard formData.isValid else { return }
        var workingForm = formData

        if workingForm.profileImageData == nil,
           let image = workingForm.profileImage {
            workingForm.setImage(image)
        }

        formData = workingForm

        if var pet = existingPet {
            pet = workingForm.applying(to: pet)
            session.updatePet(pet)
        } else {
            let ownerId = session.currentUser?.id ?? UUID()
            var newPet = workingForm.makePet(userId: ownerId)
            newPet.profileImageData = workingForm.profileImageData
            session.addPet(newPet)
        }

        dismiss()
    }
}

#if DEBUG
private struct PetRegistrationPreviewContent: View {
    @StateObject private var previewSession: SessionViewModel
    private let mode: Mode

    init(mode: Mode) {
        let session: SessionViewModel
        switch mode {
        case .new:
            session = PreviewSessionFactory.makeSession(pets: [])
        case .edit:
            session = PreviewSessionFactory.makeSession()
        }
        _previewSession = StateObject(wrappedValue: session)
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            switch mode {
            case .new:
                PetRegistrationView()
            case .edit:
                PetRegistrationView(pet: previewSession.pets.first)
            }
        }
        .environmentObject(previewSession)
    }

    enum Mode { case new, edit }
}

struct PetRegistrationView_Light_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        PetRegistrationPreviewContent(mode: .new)
            .preferredColorScheme(.light)
            .previewDisplayName("등록 - 라이트")
    }
}

struct PetRegistrationView_Dark_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        PetRegistrationPreviewContent(mode: .edit)
            .preferredColorScheme(.dark)
            .previewDisplayName("수정 - 다크")
    }
}
#endif
