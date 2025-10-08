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
    @State private var showingOrderSheet = false
    @State private var customOrder: [UUID] = []

    private var sortedPets: [Pet] {
        if customOrder.isEmpty == false {
            let orderMap = Dictionary(uniqueKeysWithValues: customOrder.enumerated().map { ($0.element, $0.offset) })
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
                            HomeHeaderView(
                                name: session.currentUser?.name ?? "사용자",
                                onAddPet: { showingPetRegistration = true },
                                hasPets: session.pets.isEmpty == false,
                                onReorderTap: { openReorderSheet() }
                            )

                            ForEach(sortedPets) { pet in
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
        .sheet(isPresented: $showingOrderSheet) {
            PetOrderSheet(
                pets: session.pets,
                initialOrder: customOrder,
                onComplete: { newOrder in
                    if newOrder != customOrder {
                        customOrder = newOrder
                        session.updatePetOrder(newOrder)
                    }
                }
            )
        }
        .onAppear {
            syncOrder(with: session.pets)
        }
        .onChange(of: session.pets) { pets in
            syncOrder(with: pets)
        }
        .onChange(of: session.currentUser?.petOrder ?? []) { _ in
            syncOrder(with: session.pets)
        }
        .onChange(of: session.currentUser?.id) { _ in
            syncOrder(with: session.pets)
        }
    }

    private func openReorderSheet() {
        guard session.pets.isEmpty == false else { return }
        syncOrder(with: session.pets)
        showingOrderSheet = true
    }

    private func syncOrder(with pets: [Pet]) {
        let ids = pets.map(\.id)
        guard ids.isEmpty == false else {
            customOrder = []
            return
        }
        var updatedOrder = customOrder

        if showingOrderSheet == false,
           let storedOrder = session.currentUser?.petOrder,
           storedOrder.isEmpty == false,
           storedOrder != customOrder {
            updatedOrder = storedOrder
        }

        if updatedOrder.isEmpty {
            updatedOrder = ids
        } else {
            updatedOrder = updatedOrder.filter(ids.contains)
            for id in ids where updatedOrder.contains(id) == false {
                updatedOrder.append(id)
            }
        }

        if updatedOrder != customOrder {
            customOrder = updatedOrder
            if showingOrderSheet == false,
               session.currentUser != nil,
               session.currentUser?.petOrder != updatedOrder {
                session.updatePetOrder(updatedOrder)
            }
        }
    }
}

// MARK: - Header

private struct HomeHeaderView: View {
    let name: String
    let onAddPet: () -> Void
    let hasPets: Bool
    let onReorderTap: () -> Void

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

            Button(action: onReorderTap) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(hasPets ? AppColor.orange : AppColor.orange.opacity(0.3))
            }
            .disabled(hasPets == false)
            .accessibilityLabel("순서 변경")

            Button(action: onAddPet) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColor.orange)
            }
            .accessibilityLabel("반려동물 추가")
        }
    }
}

// MARK: - Pet Overview Section

private struct PetOverviewSection: View {
    let pet: Pet

    var body: some View {
        PetDetailCard(pet: pet)
    }
}

private struct PetDetailCard: View {
    let pet: Pet

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.peach, AppColor.orange.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 14)

            VStack(alignment: .leading, spacing: 24) {
                headerSection
                detailPanel
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(pet.name)
                    .appFont(26, weight: .bold)
                    .foregroundStyle(AppColor.white)

                Text(speciesLabel)
                    .appFont(15, weight: .medium)
                    .foregroundStyle(AppColor.white.opacity(0.85))

                if let adoption = adoptionText {
                    Label("함께한 지 \(adoption)", systemImage: "calendar")
                        .appFont(13, weight: .semibold)
                        .foregroundStyle(AppColor.white.opacity(0.85))
                }
            }

            Spacer()

            PetHeroImageView(pet: pet)
                .frame(width: 140, height: 140)
        }
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            metricsRow

            traitChips

            specialNotesSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColor.white.opacity(0.96))
        )
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    private var metricsRow: some View {
        HStack(alignment: .center, spacing: 20) {
            metricColumn(
                title: "나이",
                value: ageText,
                subtitle: birthText.map { "생일 \($0)" }
            )

            Divider()
                .frame(height: 50)
                .overlay(AppColor.lightGray.opacity(0.6))

            metricColumn(
                title: "몸무게",
                value: weightText ?? "-",
                subtitle: "등록일 \(registrationText)"
            )

            Spacer(minLength: 0)
        }
    }

    private func metricColumn(title: String, value: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(12, weight: .semibold)
                .foregroundStyle(AppColor.subText)
            Text(value)
                .appFont(20, weight: .bold)
                .foregroundStyle(AppColor.ink)
            if let subtitle {
                Text(subtitle)
                    .appFont(11)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var traitChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                infoChip(icon: "figure.stand", text: pet.gender)
                infoChip(icon: "bandage.fill", text: pet.isNeutered ? "중성화 완료" : "중성화 미완료")
                if let birth = birthText {
                    infoChip(icon: "gift.fill", text: "생일 \(birth)")
                }
                if let weightText {
                    infoChip(icon: "scalemass", text: weightText)
                }
                if let adoptionDDay = adoptionDDayChip {
                    infoChip(icon: "calendar.badge.heart", text: adoptionDDay)
                }
                if let birthDDay = birthDDayChip {
                    infoChip(icon: "calendar.badge.plus", text: birthDDay)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var specialNotesSection: some View {
        if let note = pet.existingConditions, note.isEmpty == false {
            VStack(alignment: .leading, spacing: 10) {
                Label("특이사항", systemImage: "doc.text")
                    .appFont(14, weight: .semibold)
                    .foregroundColor(AppColor.orange)

                Text(note)
                    .appFont(15)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColor.lightGray.opacity(0.25))
            )
        }
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColor.orange)
            Text(text)
                .appFont(13, weight: .medium)
                .foregroundStyle(AppColor.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColor.lightGray)
        )
    }

    private var ageText: String {
        let years = pet.calculatedAge
        return years > 0 ? "\(years)살" : "정보 없음"
    }

    private var weightText: String? {
        guard let weight = pet.weight else { return nil }
        return String(format: "%.1f", weight) + "kg"
    }

    private var birthText: String? {
        pet.birthDate.map { PetDetailCard.dateFormatter.string(from: $0) }
    }

    private var adoptionText: String? {
        guard let adoptionDate = pet.adoptionDate else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        return formatter.string(from: adoptionDate, to: Date())
    }

    private var registrationText: String {
        PetDetailCard.dateFormatter.string(from: pet.registrationDate)
    }

    private var adoptionDDayChip: String? {
        guard let adoptionDate = pet.adoptionDate else { return nil }
        return Self.ddayChipText(for: adoptionDate, prefix: "입양")
    }

    private var birthDDayChip: String? {
        guard let birthDate = pet.birthDate else { return nil }
        return Self.ddayChipText(for: birthDate, prefix: "생일")
    }

    private var speciesLabel: String {
        if let breed = pet.breed, breed.isEmpty == false {
            return "\(pet.species) • \(breed)"
        }
        return pet.species
    }

    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static func ddayChipText(for date: Date, prefix: String) -> String? {
        let days = daysFromToday(to: date)
        guard abs(days) <= 10 else { return nil }
        if days == 0 { return "\(prefix) D-Day" }
        return days > 0 ? "\(prefix) D-\(days)" : "\(prefix) D+\(-days)"
    }

    private static func daysFromToday(to date: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfToday, to: targetDay)
        return components.day ?? 0
    }
}

private struct PetHeroImageView: View {
    let pet: Pet

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.white.opacity(0.45), AppColor.peach.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            heroImage
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 6, x: 0, y: 4)
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private var heroImage: some View {
        if let url = resolvedImageURL {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholder
            }
        } else if let name = pet.profileImageName,
                  UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.circle")
            .resizable()
            .scaledToFit()
            .foregroundColor(AppColor.orange.opacity(0.35))
            .padding(18)
            .background(AppColor.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

private struct PetOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pets: [Pet]
    let initialOrder: [UUID]
    let onComplete: ([UUID]) -> Void
    @State private var items: [PetOrderItem] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack {
                        Text(item.name)
                            .font(.body)
                        Spacer()
                        Text(item.species)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                .onMove(perform: move)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("펫 순서 정렬")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        let newOrder = items.map(\.id)
                        onComplete(newOrder)
                        dismiss()
                    }
                    .disabled(items.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .presentationDetents([.medium, .large])
        .onAppear(perform: loadItems)
    }

    private func loadItems() {
        var order = initialOrder
        let ids = pets.map(\.id)
        if order.isEmpty {
            order = ids
        } else {
            order = order.filter(ids.contains)
            for id in ids where order.contains(id) == false {
                order.append(id)
            }
        }

        items = order.compactMap { id in
            guard let pet = pets.first(where: { $0.id == id }) else { return nil }
            return PetOrderItem(id: pet.id, name: pet.name, species: pet.species)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

private struct PetOrderItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let species: String
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

    func updatePetOrder(_ order: [UUID]) async throws {
        if var current = subject.value {
            current.petOrder = order
            subject.send(current)
        }
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
