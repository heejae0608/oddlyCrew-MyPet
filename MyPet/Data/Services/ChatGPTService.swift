//
//  ChatGPTService.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import Combine
import Foundation

struct ChatResult {
    let reply: AssistantReply
    let conversationId: String?
}

final class ChatGPTService: ChatGPTServicing {
    private let apiKey: String
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let systemPrompt: String

    init(
        apiKey: String = APIConfig.OpenAI.apiKey,
        baseURL: String = APIConfig.OpenAI.baseURL,
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.apiKey = apiKey
        self.urlSession = urlSession
        self.decoder = decoder
        self.encoder = encoder

        guard let url = URL(string: baseURL) else {
            preconditionFailure("⚠️ Invalid baseURL: \(baseURL)")
        }
        self.baseURL = url

        // 시스템 프롬프트 파일 로드
        guard let promptPath = Bundle.main.path(forResource: "system_prompt", ofType: "txt"),
              let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) else {
            preconditionFailure("⚠️ system_prompt.txt 파일을 찾을 수 없습니다")
        }
        self.systemPrompt = promptContent
    }

    func send(messages: [ChatMessage], pet: Pet?, previousSummary: String?) -> AnyPublisher<ChatResult, Error> {
        let startTime = Date()
        Log.info("🚀 OpenAI Responses API 요청 시작", tag: "ChatGPT")

        guard apiKey.isEmpty == false else {
            Log.error("❌ API 키가 설정되지 않음", tag: "ChatGPT")
            return Fail(error: ChatServiceError.noAPIKey).eraseToAnyPublisher()
        }
        guard let pet else {
            Log.error("❌ 반려동물 정보가 없음", tag: "ChatGPT")
            return Fail(error: ChatServiceError.missingPet).eraseToAnyPublisher()
        }
        guard let latestUserMessage = messages.last(where: { $0.role == .user }) else {
            Log.error("❌ 전송할 메시지가 없음", tag: "ChatGPT")
            return Fail(error: ChatServiceError.noContent).eraseToAnyPublisher()
        }

        let content = latestUserMessage.content
        let existingResponseId = pet.responseId

        Log.info("📝 요청 내용: \(content.prefix(100))...", tag: "ChatGPT")
        Log.info("🐾 반려동물: \(pet.name) (\(pet.species))", tag: "ChatGPT")
        if let responseId = existingResponseId {
            Log.info("🔗 기존 Response ID: \(responseId)", tag: "ChatGPT")
        }

        return Future { promise in
            Task {
                do {
                    let result = try await self.sendResponse(
                        pet: pet,
                        content: content,
                        existingResponseId: existingResponseId,
                        previousSummary: previousSummary
                    )

                    let duration = Date().timeIntervalSince(startTime)
                    Log.info("✅ OpenAI 응답 완료 - 소요시간: \(String(format: "%.2f", duration))초", tag: "ChatGPT")
                    Log.info("📄 응답 길이: \(result.reply.message.count)자", tag: "ChatGPT")

                    promise(.success(result))
                } catch {
                    let duration = Date().timeIntervalSince(startTime)
                    Log.error("❌ OpenAI 요청 실패 - 소요시간: \(String(format: "%.2f", duration))초, 에러: \(error.localizedDescription)", tag: "ChatGPT")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func sendResponse(
        pet: Pet,
        content: String,
        existingResponseId: String?,
        previousSummary: String? = nil
    ) async throws -> ChatResult {
        // Responses API용 입력 준비
        var inputItems: [ResponseInputItem] = []

        // 시스템 프롬프트 + 펫 정보
        let petInfo = """
        이름: \(pet.name)
        종류: \(pet.species)
        품종: \(pet.breed ?? "알 수 없음")
        나이: \(pet.age)살
        성별: \(pet.gender)
        중성화: \(pet.isNeutered ? "완료" : "미완료")
        체중: \(pet.weight.map { "\($0)kg" } ?? "알 수 없음")
        기존 질환: \(pet.existingConditions ?? "없음")
        """

        let systemMessage = systemPrompt.replacingOccurrences(of: "{PET_INFO}", with: petInfo)

        inputItems.append(ResponseInputItem(
            role: "system",
            content: systemMessage
        ))

        // 사용자 메시지: 이전 대화 요약 + 현재 질문
        var userMessage = content
        if let summary = previousSummary?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
           !summary.isEmpty {
            userMessage = "이전 상담 내용:\n\(summary)\n\n현재 질문:\n\(content)"
        }

        inputItems.append(ResponseInputItem(
            role: "user",
            content: userMessage
        ))

        let requestBody = ResponsesRequest(
            input: inputItems,
            prompt: nil, // prompt 파일 대신 시스템 메시지 사용
            previousResponseId: existingResponseId,
            store: true,
            model: "gpt-4o-mini" // 시스템 메시지 사용 시 model 파라미터 필수
        )

        // 요청 로깅
        Log.info("📤 요청 내용 - 시스템 메시지 길이: \(systemMessage.count)자", tag: "ChatGPT")
        Log.info("📤 요청 내용 - 사용자 메시지: \(userMessage)", tag: "ChatGPT")
        Log.info("📤 이전 Response ID: \(existingResponseId ?? "없음")", tag: "ChatGPT")

        let payload = try encoder.encode(requestBody)
        let request = try makeRequest(path: "responses", method: "POST", body: payload)

        let requestStartTime = Date()
        let responseData = try await data(for: request)
        let requestDuration = Date().timeIntervalSince(requestStartTime)
        Log.info("📡 Responses API 요청 완료 - 소요시간: \(String(format: "%.2f", requestDuration))초", tag: "ChatGPT")

        // 원본 응답 데이터 로깅
        if let responseString = String(data: responseData, encoding: .utf8) {
            Log.info("📥 OpenAI 원본 응답: \(responseString)", tag: "ChatGPT")
        }

        let response = try decoder.decode(ResponsesResponse.self, from: responseData)

        // 응답에서 텍스트 추출
        guard let outputText = response.outputText else {
            Log.error("❌ 응답에서 텍스트를 찾을 수 없음", tag: "ChatGPT")
            throw ChatServiceError.noAssistantMessage
        }

        let assistantReply = parseAssistantReply(from: outputText)

        Log.info("📄 응답 추출 완료 (\(outputText.count)자)", tag: "ChatGPT")
        Log.info("🔗 Response ID: \(response.id)", tag: "ChatGPT")

        return ChatResult(reply: assistantReply, conversationId: response.id)
    }

    private func parseAssistantReply(from content: String) -> AssistantReply {
        // ```json 코드 블록 제거
        let cleanedContent = content
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "\n```", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        Log.debug("JSON 파싱 시도 - 정리된 내용 길이: \(cleanedContent.count)자", tag: "ChatGPT")
        Log.debug("JSON 파싱 시도 - 내용 미리보기: \(cleanedContent.prefix(200))...", tag: "ChatGPT")

        guard let data = cleanedContent.data(using: .utf8),
              let dto = try? decoder.decode(AssistantReplyDTO.self, from: data) else {
            Log.warning("AssistantReplyDTO 파싱 실패, 원본 텍스트 사용", tag: "ChatGPT")
            Log.debug("파싱 실패한 내용: \(cleanedContent)", tag: "ChatGPT")
            return AssistantReply(
                message: content,
                conversationSummary: nil,
                status: .unknown,
                questions: [],
                checklist: [],
                urgencyLevel: .unknown,
                vetConsultationNeeded: false,
                vetConsultationReason: nil,
                nextSteps: []
            )
        }

        let reply = dto.domainModel
        Log.debug("파싱 성공 - summary: \(reply.conversationSummary ?? "nil"), urgency: \(reply.urgencyLevel)", tag: "ChatGPT")
        return reply
    }

    private func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw ChatServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        request.httpBody = body
        return request
    }

    private func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.invalidResponseBody("HTTPURLResponse 변환 실패")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ChatServiceError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        return data
    }

    private func emptyJSONBody() throws -> Data {
        try encoder.encode([String: String]())
    }
}

// MARK: - DTOs (Responses API)

private struct ResponsesRequest: Encodable {
    let input: [ResponseInputItem]
    let prompt: ResponsePrompt?
    let previousResponseId: String?
    let store: Bool
    let model: String?

    enum CodingKeys: String, CodingKey {
        case input
        case prompt
        case previousResponseId = "previous_response_id"
        case store
        case model
    }
}

private struct ResponsePrompt: Encodable {
    let id: String
}

private struct ResponseInputItem: Encodable {
    let role: String
    let content: String
}

private struct ResponsesResponse: Decodable {
    let id: String
    let object: String
    let createdAt: Int
    let output: [OutputItem]

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt = "created_at"
        case output
    }

    // 편의 프로퍼티: output_text 추출
    var outputText: String? {
        for item in output {
            if item.type == "message" {
                for content in item.content ?? [] {
                    if content.type == "output_text" {
                        return content.text
                    }
                }
            }
        }
        return nil
    }
}

private struct OutputItem: Decodable {
    let type: String
    let content: [OutputContent]?
}

private struct OutputContent: Decodable {
    let type: String
    let text: String?
}

private struct AssistantReplyDTO: Decodable {
    let reasoningBrief: String?
    let finalResponse: FinalResponse

    enum CodingKeys: String, CodingKey {
        case reasoningBrief = "reasoning_brief"
        case finalResponse = "final_response"
    }

    struct FinalResponse: Decodable {
        let conversationSummary: String?
        let aiResponse: AIResponse
        let checklist: [ChecklistItem]?
        let urgencyLevel: String?
        let vetConsultation: VetConsultation?
        let nextSteps: [NextStep]?

        enum CodingKeys: String, CodingKey {
            case conversationSummary = "conversation_summary"
            case aiResponse = "ai_response"
            case checklist = "checklist"
            case urgencyLevel = "urgency_level"
            case vetConsultation = "vet_consultation"
            case nextSteps = "next_steps"
        }

        struct AIResponse: Decodable {
            let message: String
            let status: String?
            let questions: [String]?
        }

        struct ChecklistItem: Decodable {
            let item: String
            let importance: String?
        }

        struct VetConsultation: Decodable {
            let recommended: Bool
            let reason: String?
        }

        struct NextStep: Decodable {
            let step: String
            let importance: String?
        }
    }

    var domainModel: AssistantReply {
        let level = UrgencyLevel(rawValue: finalResponse.urgencyLevel ?? "") ?? .unknown
        let status = ConversationStatus(rawValue: finalResponse.aiResponse.status ?? "") ?? .unknown
        let checklist = finalResponse.checklist?.map {
            ChecklistItem(item: $0.item, importance: $0.importance ?? "medium")
        } ?? []
        let steps = finalResponse.nextSteps?.map {
            NextStep(step: $0.step, importance: $0.importance ?? "medium")
        } ?? []

        return AssistantReply(
            message: finalResponse.aiResponse.message,
            conversationSummary: finalResponse.conversationSummary,
            status: status,
            questions: finalResponse.aiResponse.questions ?? [],
            checklist: checklist,
            urgencyLevel: level,
            vetConsultationNeeded: finalResponse.vetConsultation?.recommended ?? false,
            vetConsultationReason: finalResponse.vetConsultation?.reason,
            nextSteps: steps
        )
    }
}

// MARK: - Errors

enum ChatServiceError: Error, LocalizedError {
    case noAPIKey
    case missingPet
    case invalidURL
    case invalidResponseBody(String)
    case httpError(statusCode: Int, body: String)
    case noAssistantMessage
    case noContent

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API 키가 설정되지 않았습니다."
        case .missingPet:
            return "반려동물 정보가 없습니다."
        case .invalidURL:
            return "잘못된 요청 URL입니다."
        case .invalidResponseBody(let body):
            return "잘못된 응답: \(body)"
        case .httpError(let statusCode, let body):
            return "HTTP 오류 (\(statusCode)): \(body)"
        case .noAssistantMessage:
            return "어시스턴트 응답을 찾을 수 없습니다."
        case .noContent:
            return "보낼 메시지가 없습니다."
        }
    }
}
