//
//  PetUseCase.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Foundation

protocol PetUseCaseInterface {
    func addPet(_ pet: Pet)
    func updatePet(_ pet: Pet)
    func removePet(with id: UUID)
    func clearAllPets()
}

final class PetUseCase: PetUseCaseInterface {
    private let userRepository: UserRepositoryInterface
    private let petRepository: PetRepositoryInterface

    init(userRepository: UserRepositoryInterface, petRepository: PetRepositoryInterface) {
        self.userRepository = userRepository
        self.petRepository = petRepository
    }

    func addPet(_ pet: Pet) {
        Task {
            do {
                try await petRepository.addPet(pet)
                Log.info("펫 추가 완료: \(pet.name)", tag: "PetUseCase")
            } catch {
                Log.error("펫 추가 실패: \(error.localizedDescription)", tag: "PetUseCase")
            }
        }
    }

    func updatePet(_ pet: Pet) {
        Task {
            do {
                try await petRepository.updatePet(pet)
                Log.info("펫 업데이트 완료: \(pet.name)", tag: "PetUseCase")
            } catch {
                Log.error("펫 업데이트 실패: \(error.localizedDescription)", tag: "PetUseCase")
            }
        }
    }

    func removePet(with id: UUID) {
        Task {
            do {
                try await petRepository.removePet(with: id)
                Log.info("펫 삭제 완료: \(id.uuidString)", tag: "PetUseCase")
            } catch {
                Log.error("펫 삭제 실패: \(error.localizedDescription)", tag: "PetUseCase")
            }
        }
    }

    func clearAllPets() {
        petRepository.clearAllPets()
        Log.warning("모든 펫 클리어", tag: "PetUseCase")
    }
}
