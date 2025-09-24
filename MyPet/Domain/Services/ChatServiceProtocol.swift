//
//  ChatServiceProtocol.swift
//  MyPet
//
//  Created by 전희재 on 9/19/25.
//

import Combine

protocol ChatGPTServicing {
    func send(messages: [ChatMessage], pet: Pet?, previousSummary: String?) -> AnyPublisher<ChatResult, Error>
}
