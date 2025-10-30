//
//  AnalyticsHelper.swift
//  OurPet
//
//  Created by Assistant on 10/28/25.
//

import Foundation
import FirebaseAnalytics

protocol OurPetAnalyticsEventRule {
    var location: String { get }
    var stepDepth01: String { get }
    var stepDepth02: String { get }
}

enum OurPetAnalyticsScreenEventType: Int, OurPetAnalyticsEventRule {
    case login
    case home
    case home_register_ourpet
    case home_edit_ourpet
    case history
    case history_detail
    case chat
    case mypage
    case mypage_opensource_library
    
    var location: String {
        switch self {
        case .login: return "로그인_화면"
        case .home, .home_register_ourpet, .home_edit_ourpet: return "홈_화면"
        case .history, .history_detail: return "상담_히스토리_화면"
        case .chat: return "채팅_화면"
        case .mypage: return "마이페이지_화면"
        case .mypage_opensource_library: return "마이페이지_화면"
        }
    }
    
    var stepDepth01: String {
        switch self {
        default: return ""
        }
    }
    
    var stepDepth02: String {
        switch self {
        case .home_register_ourpet: return "홈_반려동물_등록_화면"
        case .home_edit_ourpet: return "홈_반려동물_편집_화면"
        case .history_detail: return "상담_히스토리_상세_화면"
        case .mypage_opensource_library: return "마이페이지_오픈소스_화면"
        default: return ""
        }
    }
}

enum OurPetAnalyticsClickEventType: Int, OurPetAnalyticsEventRule {
    
    /// 로그인 > 애플 로그인
    case clicked_login_with_apple
    /// 홈 > 반려동물 등록
    case clicked_home_register_ourpet
    /// 홈 > 반려동물 등록 > 확인
    case clicked_home_register_ourpet_confirm
    /// 홈 > 반려동물 등록 > 취소
    case clicked_home_register_ourpet_cancel
    /// 홈 > 반려동물 순서 변경
    case clicked_home_change_ourpet_order
    /// 홈 > 반려동물 순서 변경 > 완료
    case clicked_home_change_ourpet_order_confirm
    /// 홈 > 반려동물 순서 변경 > 취소
    case clicked_home_change_ourpet_order_cancel
    /// 홈 > 반려동물 정보 편집
    case clicked_home_edit_ourpet
    /// 홈 > 반려동물 정보 편집 > 저장
    case clicked_home_edit_ourpet_save
    /// 홈 > 반려동물 정보 편집 > 취소
    case clicked_home_edit_ourpet_cancel
    /// 상담 히스토리 > 반려동물 변경 버튼
    case clicked_history_filter
    /// 상담 히스토리 > 반려동물 선택 닫기
    case clicked_history_filter_close
    /// 채팅 > 반려동물 변경 버튼
    case clicked_chat_filter
    /// 채팅 > 반려동물 선택 닫기
    case clicked_chat_filter_close
    /// 채팅 > 메세지 보내기
    case clicked_chat_send_message
    /// 채팅 > 우상단 리프레시 버튼 > 채팅방 바꾸기
    case clicked_chat_change_chatting_room
    /// 마이페이지 > 회원정보 저장 버튼
    case clicked_mypage_save_name
    /// 마이페이지 > 관리 버튼
    case clicked_mypage_edit_name
    /// 마이페이지 > 앱스토어에서 보기
    case clicked_mypage_go_appstore
    /// 마이페이지 > 개발자에게 문의
    case clicked_mypage_ask_for_developer
    /// 마이페이지 > 오픈소스 라이브러리
    case clicked_mypage_opensource_library
    /// 마이페이지 > 로그아웃
    case clicked_mypage_logout
    /// 마이페이지 > 로그아웃 확인
    case clicked_mypage_logout_confirm
    /// 마이페이지 > 로그아웃 취소
    case clicked_mypage_logout_cancel
    /// 마이페이지 > 회원 탈퇴
    case clicked_mypage_quit_ourpet
    /// 마이페이지 > 회원 탈퇴 > 삭제
    case clicked_mypage_quit_ourpet_confirm
    /// 마이페이지 > 회원 탈퇴 > 취소
    case clicked_mypage_quit_ourpet_cancel
    
    
    var location: String {
        switch self {
        case .clicked_login_with_apple:
            return "로그인"
        case .clicked_home_register_ourpet,
                .clicked_home_register_ourpet_confirm,
                .clicked_home_register_ourpet_cancel,
                .clicked_home_edit_ourpet,
                .clicked_home_edit_ourpet_save,
                .clicked_home_edit_ourpet_cancel,
                .clicked_home_change_ourpet_order,
                .clicked_home_change_ourpet_order_confirm,
                .clicked_home_change_ourpet_order_cancel:
            return "홈"
        case .clicked_history_filter,
                .clicked_history_filter_close:
            return "상담_히스토리"
        case .clicked_chat_filter,
                .clicked_chat_filter_close,
                .clicked_chat_change_chatting_room,
                .clicked_chat_send_message:
            return "채팅"
        case .clicked_mypage_save_name,
                .clicked_mypage_edit_name,
                .clicked_mypage_go_appstore,
                .clicked_mypage_ask_for_developer,
                .clicked_mypage_opensource_library,
                .clicked_mypage_logout,
                .clicked_mypage_logout_confirm,
                .clicked_mypage_logout_cancel,
                .clicked_mypage_quit_ourpet,
                .clicked_mypage_quit_ourpet_confirm,
                .clicked_mypage_quit_ourpet_cancel:
            return "마이페이지"
        }
    }
    
    var stepDepth01: String {
        switch self {
        case .clicked_login_with_apple:
            return "로그인_애플_로그인"
        case .clicked_home_register_ourpet,
                .clicked_home_register_ourpet_confirm,
                .clicked_home_register_ourpet_cancel:
            return "홈_반려동물_등록"
        case .clicked_home_edit_ourpet,
                .clicked_home_edit_ourpet_save,
                .clicked_home_edit_ourpet_cancel:
            return "홈_반려동물_정보_편집"
        case .clicked_home_change_ourpet_order,
                .clicked_home_change_ourpet_order_confirm,
                .clicked_home_change_ourpet_order_cancel:
            return "홈_반려동물_순서_변경"
        case .clicked_history_filter,
                .clicked_history_filter_close:
            return "상담_히스토리_반려동물_선택"
        case .clicked_chat_filter,
                .clicked_chat_filter_close:
            return "채팅_반려동물_선택"
        case .clicked_mypage_save_name,
                .clicked_mypage_edit_name:
            return "마이페이지_정보_관리"
        case .clicked_mypage_logout,
                .clicked_mypage_logout_confirm,
                .clicked_mypage_logout_cancel:
            return "마이페이지_로그아웃"
        case .clicked_mypage_quit_ourpet,
                .clicked_mypage_quit_ourpet_confirm,
                .clicked_mypage_quit_ourpet_cancel:
            return "마이페이지_회원탈퇴"
        default: return ""
        }
    }
    
    var stepDepth02: String {
        switch self {
        case .clicked_history_filter_close:
            return "선택_닫기"
        case .clicked_home_register_ourpet_confirm:
            return "등록_확인"
        case .clicked_home_register_ourpet_cancel:
            return "등록_취소"
        case .clicked_home_change_ourpet_order_confirm:
            return "순서_변경_확인"
        case .clicked_home_change_ourpet_order_cancel:
            return "순서_변경_취소"
        case .clicked_home_edit_ourpet_save:
            return "편집_저장"
        case .clicked_home_edit_ourpet_cancel:
            return "편집_취소"
        case .clicked_chat_change_chatting_room:
            return "채팅방_변경"
        case .clicked_chat_send_message:
            return "메세지_보내기"
        case .clicked_chat_filter_close:
            return "선택_닫기"
        case .clicked_mypage_save_name:
            return "사용자_정보_저장"
        case .clicked_mypage_edit_name:
            return "사용자_정보_관리"
        case .clicked_mypage_go_appstore:
            return "앱스토어_연결"
        case .clicked_mypage_ask_for_developer:
            return "개발자_문의"
        case .clicked_mypage_opensource_library:
            return "오픈소스_라이브러리"
        case .clicked_mypage_logout_confirm:
            return "로그아웃_확인"
        case .clicked_mypage_logout_cancel:
            return "로그아웃_취소"
        case .clicked_mypage_quit_ourpet_confirm:
            return "회원탈퇴_확인"
        case .clicked_mypage_quit_ourpet_cancel:
            return "회원탈퇴_취소"
        default : return ""
        }
    }
}

/// Firebase Analytics 환경별 관리 헬퍼
enum AnalyticsHelper {
    
    /// 환경별 이벤트 전송 (DEV/LIVE 모두 접두사 추가하여 분리)
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        let environment = AppEnvironment.current
        
        // 환경별 접두사 추가하여 이벤트 전송
        let eventName = "\(environment.rawValue.uppercased())_\(name)"
        let eventParameters = parameters ?? [:]
        
        Log.info("Analytics 이벤트 전송: \(eventName)", tag: "Analytics")
        Analytics.logEvent(eventName, parameters: eventParameters)
    }
    
    /// 사용자 속성 설정 (환경별 접두사 추가)
    static func setUserProperty(_ value: String?, forName name: String) {
        let environment = AppEnvironment.current
        
        let propertyName = "\(environment.rawValue.uppercased())_\(name)"
        Log.info("Analytics 사용자 속성 설정: \(propertyName) = \(value ?? "nil")", tag: "Analytics")
        Analytics.setUserProperty(value, forName: propertyName)
    }
    
    /// 사용자 ID 설정 (환경별 접두사 추가)
    static func setUserId(_ userId: String?) {
        let environment = AppEnvironment.current
        
        let prefixedUserId = userId != nil ? "\(environment.rawValue.uppercased())_\(userId!)" : nil
        Log.info("Analytics 사용자 ID 설정: \(prefixedUserId ?? "nil")", tag: "Analytics")
        Analytics.setUserID(prefixedUserId)
    }
}

// MARK: - 편의 메서드들
extension AnalyticsHelper {
    
    /// 화면 조회 이벤트
    static func logScreenView(_ screenName: String, screenClass: String? = nil) {
        var parameters: [String: Any] = [:]
        if let screenClass = screenClass {
            parameters["screen_class"] = screenClass
        }
        logEvent("screen_view", parameters: parameters)
    }
    
    /// 버튼 클릭 이벤트
    static func logButtonClick(_ buttonName: String, screenName: String? = nil) {
        var parameters: [String: Any] = ["button_name": buttonName]
        if let screenName = screenName {
            parameters["screen_name"] = screenName
        }
        logEvent("button_click", parameters: parameters)
    }
    
    /// 사용자 액션 이벤트
    static func logUserAction(_ action: String, category: String? = nil, value: Double? = nil) {
        var parameters: [String: Any] = ["action": action]
        if let category = category {
            parameters["category"] = category
        }
        if let value = value {
            parameters["value"] = value
        }
        logEvent("user_action", parameters: parameters)
    }
}

extension AnalyticsHelper {
    /// 화면 이벤트
    static func sendScreenEvent(event: OurPetAnalyticsScreenEventType) {
      self.sendBaseEvent(eventName: "ourpet_screen_event", type: event)
    }
    
    /// 클릭 이벤트
    static func sendClickEvent(event: OurPetAnalyticsClickEventType) {
      self.sendBaseEvent(eventName: "ourpet_click_event", type: event)
    }
    
    static func sendBaseEvent<T: OurPetAnalyticsEventRule>(eventName: String, type: T) {
      let requestParameters: [String: Any] = [
        "location": type.location,
        "Step_depth_01": type.stepDepth01,
        "Step_depth_02": type.stepDepth02
      ]
      
      Analytics.logEvent(eventName, parameters: requestParameters)
      
      Log.info("OurPet Analytics [Event Name] - \(eventName)")
      Log.info("OurPet Analytics [Event Location] - \(type.location)")
      Log.info("OurPet Analytics [Event Depth 01] - \(type.stepDepth01)")
      Log.info("OurPet Analytics [Event Depth 02] - \(type.stepDepth02)")
    }
}
