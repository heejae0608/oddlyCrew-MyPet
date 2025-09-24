//
//  UserRepositoryInterface.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine

protocol UserRepositoryInterface {
    var userPublisher: AnyPublisher<User?, Never> { get }
    var currentUser: User? { get }

    func bootstrap()
    func login(user: User)
    func logout()
    func updateUser(_ update: (inout User) -> Void)
}
