//
//  HomeView.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI
import UIKit
import Combine

struct HomeView: View {
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetRegistration = false
    @State private var selectedPetID: UUID?

    private var selectedPet: Pet? {
        guard let id = selectedPetID else { return session.pets.first }
        return session.pets.first(where: { $0.id == id }) ?? session.pets.first
    }

    private var orderedPets: [Pet] {
        guard let selected = selectedPet else { return session.pets }
        let others = session.pets.filter { $0.id != selected.id }
        return [selected] + others
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                AppColor.lightGray
                    .ignoresSafeArea()

                if session.pets.isEmpty {
                    VStack {
                        Spacer()
                        HomeEmptyState {
                            showingPetRegistration = true
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            HomeHeaderView(name: session.currentUser?.name ?? "사용자")

                            PetSelectorView(
                                pets: orderedPets,
                                selectedPetID: selectedPet?.id,
                                onSelect: { pet in
                                    selectedPetID = pet.id
                                },
                                onRegisterTap: {
                                    showingPetRegistration = true
                                }
                            )

                            if let pet = selectedPet {
                                PetOverviewSection(pet: pet)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 140)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPetRegistration) {
            PetRegistrationView()
                .environmentObject(session)
        }
        .onAppear {
            if selectedPetID == nil {
                selectedPetID = session.pets.first?.id
            }
        }
        .onChange(of: session.pets) { pets in
            guard let currentID = selectedPetID else {
                selectedPetID = pets.first?.id
                return
            }

            if pets.contains(where: { $0.id == currentID }) == false {
                selectedPetID = pets.first?.id
            }
        }
    }
}

// MARK: - Header

private struct HomeHeaderView: View {
    let name: String

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good Morning!"
        case 12..<18: return "Good Afternoon!"
        case 18..<22: return "Good Evening!"
        default: return "Hello!"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .foregroundColor(AppColor.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

// MARK: - Pet Selector

private struct PetSelectorView: View {
    let pets: [Pet]
    let selectedPetID: UUID?
    let onSelect: (Pet) -> Void
    let onRegisterTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pets) { pet in
                    PetChip(pet: pet, isSelected: pet.id == selectedPetID) {
                        onSelect(pet)
                    }
                }

                Button(action: onRegisterTap) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(AppColor.orange)
                        .frame(width: 44, height: 44)
                        .background(AppColor.orange.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct PetChip: View {
    let pet: Pet
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(isSelected ? .white : AppColor.orange)

                Text(pet.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(isSelected ? AppColor.orange : AppColor.lightGray)
            )
        }
    }
}

// MARK: - Pet Overview Section

private struct PetOverviewSection: View {
    let pet: Pet

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            PetImageCard(pet: pet)

            PetInfoCard(icon: "clock", title: "Age") {
                InfoValueView(value: "\(pet.calculatedAge)", unit: "Years")
            }

            PetInfoCard(icon: "scalemass", title: "Weight") {
                InfoValueView(value: weightValue, unit: "Kg")
            }

            PetInfoCard(icon: "pawprint", title: "Species") {
                InfoValueView(value: pet.species, unit: pet.breed)
            }

            PetInfoCard(icon: "figure.stand", title: "Gender") {
                InfoValueView(value: pet.gender, unit: pet.isNeutered ? "Neutered" : "Not neutered")
            }

            if let note = pet.existingConditions, note.isEmpty == false {
                PetInfoCard(icon: "doc.text", title: "About") {
                    Text(note)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .gridCellColumns(2)
            }
        }
    }

    private var weightValue: String {
        guard let weight = pet.weight else { return "-" }
        return String(format: "%.1f", weight)
    }
}

private struct PetImageCard: View {
    let pet: Pet

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.white)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 10)

            GeometryReader { proxy in
                VStack {
                    Spacer(minLength: 12)

                    petImage
                        .frame(maxWidth: proxy.size.width * 0.8)
                        .frame(maxHeight: proxy.size.height * 0.7)

                    Spacer(minLength: 12)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 170)
    }

    @ViewBuilder
    private var petImage: some View {
        if let url = resolvedImageURL {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                placeholder
            }
        } else if let name = pet.profileImageName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFit()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(AppColor.orange.opacity(0.35))
            .padding(18)
    }

    private var resolvedImageURL: URL? {
        guard let string = pet.profileImageName,
              let url = URL(string: string),
              string.lowercased().hasPrefix("http") else {
            return nil
        }
        return url
    }
}

private struct PetInfoCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content

    init(icon: String, title: String, @ViewBuilder body: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = body()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColor.orange)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            HStack {
                Spacer()
                content
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.white)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 10)
        )
    }
}

private struct InfoValueView: View {
    let value: String
    let unit: String?

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.primary)

            if let unit, unit.isEmpty == false {
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Empty State

private struct HomeEmptyState: View {
    let onRegisterTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(AppColor.orange.opacity(0.5))

            Text("먼저 반려동물을 등록해 주세요")
                .font(.title3)
                .fontWeight(.semibold)

            Text("등록된 펫이 없어요. 새로운 친구를 추가하면 개별 프로필과 건강 정보를 한눈에 볼 수 있습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onRegisterTap) {
                Text("반려동물 등록")
                    .font(.headline)
                    .foregroundColor(.white)
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
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 12)
        )
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        Group {
            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession())
                .previewDisplayName("With Pets")

            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession(pets: []))
                .previewDisplayName("Empty State")
        }
    }
}

enum PreviewSessionFactory {
    @MainActor
    static func makeSession(pets: [Pet] = samplePets) -> SessionViewModel {
        let petRepository = PreviewPetRepository(initialPets: pets)
        let authUseCase = PreviewAuthUseCase(initialUser: sampleUser)
        let petUseCase = PreviewPetUseCase(petRepository: petRepository)
        let session = SessionViewModel(
            authUseCase: authUseCase,
            petUseCase: petUseCase,
            petRepository: petRepository
        )
        return session
    }

    private static let sampleUser = User(
        appleUserID: "preview-user",
        name: "Martin Lee",
        email: "martin@example.com"
    )

    private static let samplePets: [Pet] = [
        Pet(
            userId: sampleUser.id,
            name: "Choco",
            species: "Dog",
            breed: "Corgi",
            gender: "Male",
            isNeutered: true,
            weight: 9.2,
            profileImageName: nil,
            existingConditions: "Allergic to chicken",
            birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
            adoptionDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())
        ),
        Pet(
            userId: sampleUser.id,
            name: "Nabi",
            species: "Cat",
            breed: "Calico",
            gender: "Female",
            isNeutered: false,
            weight: 4.1,
            profileImageName: nil,
            existingConditions: "No known issues",
            birthDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
            adoptionDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())
        )
    ]
}

private final class PreviewAuthUseCase: AuthUseCaseInterface {
    var userPublisher: AnyPublisher<User?, Never> {
        subject.eraseToAnyPublisher()
    }

    var currentUser: User? {
        subject.value
    }

    private let subject: CurrentValueSubject<User?, Never>

    init(initialUser: User?) {
        subject = CurrentValueSubject(initialUser)
    }

    func bootstrap() {
        subject.send(subject.value)
    }

    func signInWithApple(idToken: String, nonce: String, name: String?, email: String?) async throws {}

    func logout() async throws {}

    func deleteAccount() async throws {}

    func restoreSession() async throws -> User? {
        subject.value
    }
}

private final class PreviewPetUseCase: PetUseCaseInterface {
    private let petRepository: PetRepositoryInterface

    init(petRepository: PetRepositoryInterface) {
        self.petRepository = petRepository
    }

    func addPet(_ pet: Pet) {
        Task { try? await petRepository.addPet(pet) }
    }

    func updatePet(_ pet: Pet) {
        Task { try? await petRepository.updatePet(pet) }
    }

    func removePet(with id: UUID) {
        Task { try? await petRepository.removePet(with: id) }
    }

    func clearAllPets() {
        petRepository.clearAllPets()
    }
}

private final class PreviewPetRepository: PetRepositoryInterface {
    private let subject: CurrentValueSubject<[Pet], Never>

    init(initialPets: [Pet]) {
        subject = CurrentValueSubject(initialPets)
    }

    var petsPublisher: AnyPublisher<[Pet], Never> {
        subject.eraseToAnyPublisher()
    }

    var pets: [Pet] {
        subject.value
    }

    func loadPets(for userId: UUID) async throws {}

    func addPet(_ pet: Pet) async throws {
        var items = subject.value
        items.append(pet)
        subject.send(items)
    }

    func updatePet(_ pet: Pet) async throws {
        var items = subject.value
        if let index = items.firstIndex(where: { $0.id == pet.id }) {
            items[index] = pet
            subject.send(items)
        }
    }

    func removePet(with id: UUID) async throws {
        let items = subject.value.filter { $0.id != id }
        subject.send(items)
    }

    func clearAllPets() {
        subject.send([])
    }
}
#endif
