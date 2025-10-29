//
//  AnalyticsHelper.swift
//  OurPet
//
//  Created by Assistant on 10/28/25.
//

import Foundation
import FirebaseAnalytics

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
