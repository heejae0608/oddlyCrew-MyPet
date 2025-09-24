//
//  PetRegistrationView.swift
//  MyPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI
import PhotosUI

struct PetRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionViewModel
    
    @State private var name = ""
    @State private var selectedSpecies = "강아지"
    @State private var breed = ""
    @State private var age = 1
    @State private var selectedGender = "수컷"
    @State private var isNeutered = false
    @State private var weight = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var existingConditions = ""
    
    private let species = ["강아지", "고양이"]
    private let genders = ["수컷", "암컷"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("기본 정보") {
                    // 프로필 사진
                    HStack {
                        Spacer()
                        VStack {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.circle.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(.gray)
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text("사진 선택")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    // 이름
                    HStack {
                        Text("이름")
                        TextField("반려동물 이름을 입력하세요", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 종류
                    HStack {
                        Picker("종류", selection: $selectedSpecies) {
                            ForEach(species, id: \.self) { species in
                                Text(species).tag(species)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // 품종 (선택사항)
                    HStack {
                        Text("품종")
                        TextField("품종 (선택사항)", text: $breed)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section("상세 정보") {
                    // 나이
                    HStack {
                        Text("나이")
                        Stepper("\(age)살", value: $age, in: 0...30)
                    }
                    
                    // 성별
                    HStack {
                        Text("성별")
                        Picker("성별", selection: $selectedGender) {
                            ForEach(genders, id: \.self) { gender in
                                Text(gender).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // 중성화 여부
                    HStack {
                        Text("중성화")
                        Spacer()
                        Toggle("", isOn: $isNeutered)
                    }
                    
                    // 몸무게 (선택사항)
                    HStack {
                        Text("몸무게")
                        TextField("몸무게 (kg, 선택사항)", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("기존 질병 / 특이사항")
                        TextEditor(text: $existingConditions)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                        Text("있다면 입력해주세요 (예: 알러지, 만성 질환 등)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("반려동물 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("등록") {
                        registerPet()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    private func registerPet() {
        let weightValue = Double(weight.isEmpty ? "0" : weight) ?? 0
        let finalWeight = weightValue > 0 ? weightValue : nil
        let trimmedConditions = existingConditions.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newPet = Pet(
            userId: session.currentUser?.id ?? UUID(),
            name: name,
            species: selectedSpecies,
            breed: breed.isEmpty ? nil : breed,
            age: age,
            gender: selectedGender,
            isNeutered: isNeutered,
            weight: finalWeight,
            profileImageName: nil,
            existingConditions: trimmedConditions.isEmpty ? nil : trimmedConditions
        )
        
        session.addPet(newPet)
        dismiss()
    }
}
