//
//  HomeView.swift
//  MyPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetRegistration = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !session.pets.isEmpty {
                    // 펫이 있는 경우
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(session.pets) { pet in
                                PetCardView(pet: pet)
                            }
                        }
                        .padding()
                    }
                } else {
                    // 펫이 없는 경우
                    EmptyPetView(showingPetRegistration: $showingPetRegistration)
                }
            }
            .navigationTitle("내 반려동물")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPetRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingPetRegistration) {
                PetRegistrationView()
                    .environmentObject(session)
            }
        }
    }
}

struct PetCardView: View {
    let pet: Pet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 펫 프로필 이미지
                AsyncImage(url: URL(string: pet.profileImageName ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(pet.species)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(pet.age)살")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(pet.gender)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let weight = pet.weight {
                        Text("\(weight, specifier: "%.1f")kg")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 최근 기록
            if let lastRecord = pet.medicalHistory.last {
                VStack(alignment: .leading, spacing: 4) {
                    Text("최근 기록")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(lastRecord.title)
                        .font(.footnote)
                        .lineLimit(1)
                }
                .padding(.top, 8)
            } else if let conditions = pet.existingConditions, conditions.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    Text("특이사항")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(conditions)
                        .font(.footnote)
                        .lineLimit(2)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EmptyPetView: View {
    @Binding var showingPetRegistration: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("등록된 반려동물이 없어요")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("첫 번째 반려동물을 등록해보세요!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                showingPetRegistration = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("반려동물 등록하기")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}
