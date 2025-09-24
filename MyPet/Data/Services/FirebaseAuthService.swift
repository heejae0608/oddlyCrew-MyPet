//
//  FirebaseAuthService.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import AuthenticationServices
import FirebaseAuth
import Foundation

final class FirebaseAuthService: FirebaseAuthServiceProtocol {
    func signInWithApple(idToken: String, nonce: String) async throws -> FirebaseUserInfo {
        Log.info("FirebaseAuth Apple credential 생성 (nonce prefix: \(nonce.prefix(6)))", tag: "FirebaseAuth")
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: nil
        )

        let authResult = try await signIn(with: credential)
        let user = authResult.user
        Log.info("FirebaseAuth 로그인 성공: \(user.uid)", tag: "FirebaseAuth")
        return FirebaseUserInfo(
            uid: user.uid,
            name: user.displayName,
            email: user.email
        )
    }

    func signOut() throws {
        Log.info("FirebaseAuth 로그아웃 시도", tag: "FirebaseAuth")
        try Auth.auth().signOut()
        Log.info("FirebaseAuth 로그아웃 완료", tag: "FirebaseAuth")
    }

    func currentUser() -> FirebaseUserInfo? {
        Log.debug("FirebaseAuth currentUser 조회 시도", tag: "FirebaseAuth")
        guard let user = Auth.auth().currentUser else {
            Log.debug("FirebaseAuth currentUser 없음", tag: "FirebaseAuth")
            return nil
        }
        let providers = user.providerData.map { $0.providerID }.joined(separator: ",")
        let creation = user.metadata.creationDate?.iso8601 ?? "-"
        let lastSignIn = user.metadata.lastSignInDate?.iso8601 ?? "-"
        Log.debug(
            "FirebaseAuth currentUser 확인: uid=\(user.uid), providers=[\(providers)], emailVerified=\(user.isEmailVerified), createdAt=\(creation), lastSignIn=\(lastSignIn)",
            tag: "FirebaseAuth"
        )
        return FirebaseUserInfo(
            uid: user.uid,
            name: user.displayName,
            email: user.email
        )
    }

    func fetchIDToken(forceRefresh: Bool) async throws -> String? {
        guard let user = Auth.auth().currentUser else {
            Log.warning("ID 토큰 요청 시 currentUser가 없습니다", tag: "FirebaseAuth")
            return nil
        }

        Log.debug("ID 토큰 요청 시작 (forceRefresh: \(forceRefresh))", tag: "FirebaseAuth")
        do {
            let token: String? = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
                user.getIDTokenForcingRefresh(forceRefresh) { token, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: token)
                }
            }

            if let token {
                let prefix = token.prefix(10)
                Log.debug("ID 토큰 획득 성공 (prefix: \(prefix)...)", tag: "FirebaseAuth")
            } else {
                Log.warning("ID 토큰이 nil 로 반환되었습니다", tag: "FirebaseAuth")
            }
            return token
        } catch {
            Log.error("ID 토큰 요청 실패: \(error.localizedDescription)", tag: "FirebaseAuth")
            throw error
        }
    }

    private func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    Log.error("FirebaseAuth 로그인 실패: \(error.localizedDescription)", tag: "FirebaseAuth")
                    continuation.resume(throwing: error)
                    return
                }

                guard let authResult else {
                    let error = NSError(
                        domain: "FirebaseAuthService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "인증 결과가 비어 있습니다."]
                    )
                    Log.error("FirebaseAuth 응답이 비어 있음", tag: "FirebaseAuth")
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: authResult)
            }
        }
    }
}
