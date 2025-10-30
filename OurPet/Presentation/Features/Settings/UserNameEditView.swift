//
//  UserNameEditView.swift
//  OurPet
//
//  Renamed from UserProfileEditView on 10/29/25.
//

import SwiftUI

struct UserNameEditView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    init(currentName: String) {
        _name = State(initialValue: currentName)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("회원 정보 관리")
                    .appFont(16, weight: .semibold)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Form
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .appFont(14, weight: .semibold)
                        .foregroundStyle(AppColor.ink)
                    TextField("이름을 입력하세요", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(AppColor.inputSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColor.inputBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button(action: save) {
                Text("저장")
                    .appFont(16, weight: .semibold)
                    .foregroundStyle(AppColor.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppColor.mutedGray : AppColor.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppColor.surfaceBackground.ignoresSafeArea())
    }

    private func save() {
        AnalyticsHelper.sendClickEvent(event: .clicked_mypage_save_name)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentEmail = session.currentUser?.email
        session.updateUserProfile(name: trimmedName, email: currentEmail)
        dismiss()
    }
}


