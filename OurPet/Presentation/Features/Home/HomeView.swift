//
//  HomeView.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetRegistration = false
    @State private var showingOrderSheet = false
    @State private var editingPet: Pet?

    private var sortedPets: [Pet] {
        let order = session.petDisplayOrder
        if order.isEmpty == false {
            let orderMap = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            return session.pets.sorted { lhs, rhs in
                let lhsIndex = orderMap[lhs.id] ?? Int.max
                let rhsIndex = orderMap[rhs.id] ?? Int.max
                if lhsIndex == rhsIndex {
                    return lhs.registrationDate > rhs.registrationDate
                }
                return lhsIndex < rhsIndex
            }
        }
        return session.pets.sorted { $0.registrationDate > $1.registrationDate }
    }

    private let tipProvider = PetCareTipProvider.shared
    @State private var dailyTip: DailyTip?
    private var hasPets: Bool { session.pets.isEmpty == false }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.surfaceBackground
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    if hasPets {
                        VStack(alignment: .leading, spacing: 24) {
                            if let dailyTip {
                                TipCard(tip: dailyTip)
                            }

                            ForEach(sortedPets) { pet in
                                PetOverviewSection(
                                    pet: pet,
                                    onEdit: { editingPet = $0 }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    } else {
                        HomeEmptyState {
                            showingPetRegistration = true
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 120)
                        .padding(.bottom, 80)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("OurPet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if hasPets {
                        Button(action: openReorderSheet) {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }

                    Button {
                        showingPetRegistration = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPetRegistration) {
            PetRegistrationView()
                .environmentObject(session)
        }
        .sheet(item: $editingPet) { pet in
            PetRegistrationView(pet: pet)
                .environmentObject(session)
        }
        .sheet(isPresented: $showingOrderSheet) {
            PetOrderSheet(
                pets: session.pets,
                initialOrder: session.petDisplayOrder,
                onComplete: { newOrder in
                    session.reorderPets(with: newOrder)
                }
            )
        }
        .onAppear(perform: refreshTip)
        .onChange(of: session.pets) { _ in refreshTip() }
    }

    private func openReorderSheet() {
        guard hasPets else { return }
        showingOrderSheet = true
    }

    private func refreshTip() {
        dailyTip = tipProvider.randomTip(for: session.pets)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        Group {
            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession())
                .previewDisplayName("With Pets - Light")
                .preferredColorScheme(.light)

            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession())
                .previewDisplayName("With Pets - Dark")
                .preferredColorScheme(.dark)

            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession(pets: []))
                .previewDisplayName("Empty State - Light")
                .preferredColorScheme(.light)

            HomeView()
                .environmentObject(PreviewSessionFactory.makeSession(pets: []))
                .previewDisplayName("Empty State - Dark")
                .preferredColorScheme(.dark)
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

    func updatePetOrder(_ order: [UUID]) async throws {
        if var current = subject.value {
            current.petOrder = order
            subject.send(current)
        }
    }
    
    func updateUserName(name: String) async throws {
        
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
