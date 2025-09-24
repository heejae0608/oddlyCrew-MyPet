//
//  PetRepository.swift
//  MyPet
//
//  Created by 전희재 on 9/23/25.
//

import Combine
import Foundation

final class PetRepository: PetRepositoryInterface {
    @Published private var _pets: [Pet] = []

    var petsPublisher: AnyPublisher<[Pet], Never> {
        $_pets.eraseToAnyPublisher()
    }

    var pets: [Pet] {
        _pets
    }

    private let remotePetDataSource: RemotePetDataSourceInterface

    init(remotePetDataSource: RemotePetDataSourceInterface) {
        self.remotePetDataSource = remotePetDataSource
    }

    func loadPets(for userId: UUID) async throws {
        Log.debug("펫 목록 로드 시작 (userId: \(userId.uuidString))", tag: "PetRepository")

        let remotePets = try await remotePetDataSource.fetchPets(for: userId)

        await MainActor.run {
            self._pets = remotePets
        }

        Log.debug("펫 목록 로드 완료 (개수: \(remotePets.count))", tag: "PetRepository")
    }

    func addPet(_ pet: Pet) async throws {
        Log.debug("펫 추가 시작 (name: \(pet.name))", tag: "PetRepository")

        try await remotePetDataSource.upsertPet(pet)

        await MainActor.run {
            self._pets.append(pet)
        }

        Log.debug("펫 추가 완료", tag: "PetRepository")
    }

    func updatePet(_ pet: Pet) async throws {
        Log.debug("펫 업데이트 시작 (id: \(pet.id.uuidString))", tag: "PetRepository")

        try await remotePetDataSource.upsertPet(pet)

        await MainActor.run {
            if let index = self._pets.firstIndex(where: { $0.id == pet.id }) {
                self._pets[index] = pet
            }
        }

        Log.debug("펫 업데이트 완료", tag: "PetRepository")
    }

    func removePet(with id: UUID) async throws {
        Log.debug("펫 삭제 시작 (id: \(id.uuidString))", tag: "PetRepository")

        try await remotePetDataSource.deletePet(id: id)

        await MainActor.run {
            self._pets.removeAll { $0.id == id }
        }

        Log.debug("펫 삭제 완료", tag: "PetRepository")
    }

    func clearAllPets() {
        Log.debug("모든 펫 클리어", tag: "PetRepository")
        _pets.removeAll()
    }
}