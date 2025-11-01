//
//  RemoteAppConfigDataSource.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation
import FirebaseFirestore

protocol RemoteAppConfigDataSourceInterface {
    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo?
    func fetchNotice() async throws -> AppNotice?
}

final class RemoteAppConfigDataSource: RemoteAppConfigDataSourceInterface {
    private enum Document: String {
        case forceUpdate = "force_update"
        case notice = "notice"
    }

    private let collectionName: String
    private let database: Firestore

    init(
        database: Firestore? = nil
    ) {
        self.database = database ?? Firestore.firestore()
        self.collectionName = AppEnvironment.current.collectionName(for: "appConfig")
    }

    func fetchForceUpdateInfo() async throws -> ForceUpdateInfo? {
        Log.debug("강제 업데이트 설정 조회 시작", tag: "RemoteAppConfig")
        let snapshot = try await database
            .collection(collectionName)
            .document(Document.forceUpdate.rawValue)
            .getDocument()

        guard snapshot.exists, let data = snapshot.data() else {
            Log.debug("강제 업데이트 문서 없음", tag: "RemoteAppConfig")
            return nil
        }

        guard let info = ForceUpdateDTO(data: data)?.toDomain() else {
            Log.error("강제 업데이트 데이터 파싱 실패: \(data)", tag: "RemoteAppConfig")
            return nil
        }

        Log.debug("강제 업데이트 설정 조회 완료: minVersion=\(info.minVersion), enabled=\(info.isEnabled)", tag: "RemoteAppConfig")
        return info
    }

    func fetchNotice() async throws -> AppNotice? {
        Log.debug("공지사항 설정 조회 시작", tag: "RemoteAppConfig")
        let snapshot = try await database
            .collection(collectionName)
            .document(Document.notice.rawValue)
            .getDocument()

        guard snapshot.exists, let data = snapshot.data() else {
            Log.debug("공지사항 문서 없음", tag: "RemoteAppConfig")
            return nil
        }

        guard let notice = NoticeDTO(data: data)?.toDomain() else {
            Log.error("공지사항 데이터 파싱 실패: \(data)", tag: "RemoteAppConfig")
            return nil
        }

        Log.debug("공지사항 설정 조회 완료: enabled=\(notice.isEnabled), allowUsage=\(notice.allowUsageDuringNotice)", tag: "RemoteAppConfig")
        return notice
    }
}

// MARK: - DTO

private struct ForceUpdateDTO {
    let minVersion: String
    let title: String
    let message: String
    let isEnabled: Bool
    let storeURL: URL?

    init?(data: [String: Any]) {
        guard let minVersion = data["minVersion"] as? String else { return nil }
        self.minVersion = minVersion
        self.title = (data["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "새로운 버전이 출시되었어요"
        self.message = (data["message"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "최신 버전으로 업데이트 후 이용해주세요."
        if let urlString = data["storeUrl"] as? String {
            self.storeURL = URL(string: urlString)
        } else {
            self.storeURL = nil
        }
        self.isEnabled = data["isEnabled"] as? Bool ?? true
    }

    func toDomain() -> ForceUpdateInfo {
        ForceUpdateInfo(
            minVersion: minVersion,
            title: title,
            message: message,
            isEnabled: isEnabled,
            storeURL: storeURL
        )
    }
}

private struct NoticeDTO {
    let title: String
    let message: String
    let isEnabled: Bool
    let allowUsage: Bool

    init?(data: [String: Any]) {
        guard
            let title = data["title"] as? String,
            let message = data["message"] as? String
        else { return nil }
        self.title = title
        self.message = message
        self.isEnabled = data["isEnabled"] as? Bool ?? false
        self.allowUsage = data["allowUsageDuringNotice"] as? Bool ?? true
    }

    func toDomain() -> AppNotice {
        AppNotice(
            title: title,
            message: message,
            isEnabled: isEnabled,
            allowUsageDuringNotice: allowUsage
        )
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
