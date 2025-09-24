//
//  UserRepository.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine

final class UserRepository: UserRepositoryInterface {
    private let subject = CurrentValueSubject<User?, Never>(nil)

    var userPublisher: AnyPublisher<User?, Never> {
        subject.eraseToAnyPublisher()
    }

    var currentUser: User? {
        subject.value
    }

    init() { }

    func bootstrap() {
        subject.value = nil
    }

    func login(user: User) {
        subject.value = user
    }

    func logout() {
        subject.value = nil
    }

    func updateUser(_ update: (inout User) -> Void) {
        guard var user = subject.value else { return }
        update(&user)
        subject.value = user
    }
}
