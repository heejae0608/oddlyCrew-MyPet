//
//  LoginView.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentNonce: String?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                // 로고 및 앱 제목
                VStack(spacing: 0) {
                    Image("OurPetLogo")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .foregroundColor(AppColor.orange)
                        .padding(.bottom, -20)

                    Text("OurPet")
                        .appFont(32, weight: .bold)
                        .foregroundColor(AppColor.text)
                        .padding(.bottom, 10)

                    Text("반려동물과 함께하는 특별한 시간")
                        .appFont(15, weight: .medium)
                        .foregroundColor(AppColor.subText)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                
                if session.appState != .loading {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            let nonce = NonceUtil.randomNonceString()
                            currentNonce = nonce
                            request.nonce = NonceUtil.sha256(nonce)
                            Log.debug("Apple SignIn 요청 준비", tag: "LoginView")
                            
                            // Apple 로그인 버튼 클릭 이벤트
                            AnalyticsHelper.sendClickEvent(event: .clicked_login_with_apple)
                            // AnalyticsHelper.logButtonClick("apple_signin", screenName: "LoginView")
                            AnalyticsHelper.logEvent("apple_login_attempt", parameters: [
                                "environment": AppEnvironment.current.rawValue
                            ])
                        },
                        onCompletion: { result in
                            handleSignInWithApple(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
                    
                    Text("Apple ID로 간편하게 로그인하세요")
                        .appFont(13)
                        .foregroundColor(AppColor.subText)
                }
                
                Spacer()
            }
            
            if session.appState == .loading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView("로그인 중...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
        .onAppear {
            // 로그인 화면 진입 이벤트
            AnalyticsHelper.sendScreenEvent(event: .login)
//            AnalyticsHelper.logScreenView("LoginView")
//            AnalyticsHelper.logEvent("login_screen_viewed", parameters: [
//                "environment": AppEnvironment.current.rawValue
//            ])
        }
        .alert("로그인 오류", isPresented: $showingAlert) {
            Button("확인", role: .cancel) {
                session.resetState()
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: session.appState) {
            if case let .error(message) = session.appState {
                alertMessage = message
                showingAlert = true
            }
        }
    }
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    alertMessage = "유효하지 않은 인증 요청입니다. 다시 시도해주세요."
                    showingAlert = true
                    Log.error("Nonce 누락으로 로그인 실패", tag: "LoginView")
                    return
                }

                guard let tokenData = appleIDCredential.identityToken,
                      let idToken = String(data: tokenData, encoding: .utf8) else {
                    alertMessage = "Apple ID 토큰을 가져오지 못했습니다."
                    showingAlert = true
                    Log.error("Apple ID 토큰 파싱 실패", tag: "LoginView")
                    return
                }

                let name = appleIDCredential.fullName?.formatted()
                let email = appleIDCredential.email

                session.signInWithApple(
                    idToken: idToken,
                    nonce: nonce,
                    name: name,
                    email: email
                )
                currentNonce = nil
                Log.info("Apple 로그인 처리 시작", tag: "LoginView")
                
                // Apple 로그인 성공 이벤트
                AnalyticsHelper.logEvent("apple_login_success", parameters: [
                    "environment": AppEnvironment.current.rawValue,
                    "has_name": name != nil ? "true" : "false",
                    "has_email": email != nil ? "true" : "false"
                ])
            }
        case .failure(let error):
            currentNonce = nil
            alertMessage = "로그인에 실패했습니다: \(error.localizedDescription)"
            showingAlert = true
            Log.error("Apple 로그인 오류: \(error.localizedDescription)", tag: "LoginView")
            
            // Apple 로그인 실패 이벤트
            AnalyticsHelper.logEvent("apple_login_failure", parameters: [
                "environment": AppEnvironment.current.rawValue,
                "error_message": error.localizedDescription
            ])
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        Group {
            LoginView()
                .environmentObject(PreviewSessionFactory.makeSession(pets: []))
        }
    }
}
