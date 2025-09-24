//
//  PetRepositoryInterface.swift
//  MyPet
//
//  Created by 전희재 on 9/23/25.
//

import Combine
import Foundation

protocol PetRepositoryInterface {
    var petsPublisher: AnyPublisher<[Pet], Never> { get }
    var pets: [Pet] { get }

    func loadPets(for userId: UUID) async throws
    func addPet(_ pet: Pet) async throws
    func updatePet(_ pet: Pet) async throws
    func removePet(with id: UUID) async throws
    func clearAllPets()
}