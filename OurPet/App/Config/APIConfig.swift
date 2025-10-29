//
//  APIConfig.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import Foundation

// MARK: - API 설정 관리
class APIConfig: ObservableObject {
    static let shared = APIConfig()
    
    private init() {}
    
    private static let secrets = SecretsLoader.load()
    
    private struct SecretsLoader {
        struct SecretBundle: Decodable {
            let apiKey: String?

            enum CodingKeys: String, CodingKey {
                case apiKey = "api_key"
            }
        }

        static func load() -> SecretBundle {
            let bundle = Bundle.main
            let candidates: [(name: String, ext: String)] = [
                ("openai_secrets", "json"),
                ("openai_secrets.local", "json"),
                ("openai_secrets", "json.template")
            ]

            for candidate in candidates {
                if let url = bundle.url(forResource: candidate.name, withExtension: candidate.ext) {
                    do {
                        let data = try Data(contentsOf: url)
                        let decoded = try JSONDecoder().decode(SecretBundle.self, from: data)
                        if decoded.apiKey?.isEmpty == false {
                            if candidate.ext == "json.template" {
                                Log.warning("openai_secrets.json.template에서 API 키를 로드했습니다. 템플릿 파일은 Git에 커밋되지 않도록 주의하세요.", tag: "APIConfig")
                            }
                            return decoded
                        }
                    } catch {
                        Log.warning("\(candidate.name).\(candidate.ext) 파싱 실패: \(error.localizedDescription)", tag: "APIConfig")
                    }
                }
            }

            return SecretBundle(apiKey: nil)
        }
    }
    
    // MARK: - OpenAI API 설정 (Responses API)
    struct OpenAI {
        static var apiKey: String {
            // 환경별 API 키 우선, 없으면 시크릿 파일, 마지막으로 환경변수
            let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            let devKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY_DEV"]
            let liveKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY_LIVE"]
            
            switch AppEnvironment.current {
            case .dev:
                return devKey ?? APIConfig.secrets.apiKey ?? envKey ?? ""
            case .live:
                return liveKey ?? APIConfig.secrets.apiKey ?? envKey ?? ""
            }
        }

        static let baseURL = "https://api.openai.com/v1/"
        
        // 환경별 저장된 프롬프트 ID (OpenAI Platform에서 생성)
        static var storedPromptId: String {
            switch AppEnvironment.current {
            case .dev:
                return "pmpt_6901687aaba88197b6d82527cc3398bb059fecb32a0b4aef" // DEV용 프롬프트 ID
            case .live:
                return "pmpt_68ff07855b788197ba3682f46f6929140f542f5bc61d5ced" // 기존 LIVE용 프롬프트 ID
            }
        }
    }
    
    // MARK: - Claude API 설정 (향후 확장용)
    struct Claude {
        static let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
        static let model = "claude-3-sonnet-20240229"
    }
}
