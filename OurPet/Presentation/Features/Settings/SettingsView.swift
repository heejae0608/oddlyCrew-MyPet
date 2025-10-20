//
//  SettingsView.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.openURL) var openURL
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var errorMessage: String?
    @State private var showingEmailCopiedAlert = false
    
    private let email = SendEmailToDeveloper(
        toAddress: "oddlycrew@gmail.com",
        subject: "OurPet 문의사항",
        messageHeader: "아래에 내용을 입력해주시면,\n더욱 신속하고 정확한 처리가 가능합니다.\n\n단말기 명: \niOS 버전: \nOurPet 버전: \n문의내용: \n"
    )

    private var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        if let build = bundle.infoDictionary?["CFBundleVersion"] as? String,
           build.isEmpty == false,
           build != version {
            return "\(version) (\(build))"
        }
        return version
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColor.surfaceBackground
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Text("마이")
                            .appFont(24, weight: .bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            userInfo
                                .padding(.vertical, 10)
                            petInfo
                                .padding(.vertical, 10)
                            appInfo
                                .padding(.vertical, 12)
                            appAccountInfo
                        }
                    }
                }
            }
            .alert("로그아웃", isPresented: $showingLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    viewModel.logout()
                }
            } message: {
                Text("정말 로그아웃하시겠습니까?")
            }
            .alert("계정 삭제", isPresented: $showingDeleteAccountAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("계정과 모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?")
            }
            .overlay {
                if session.appState == .loading {
                    ZStack {
                        AppColor.overlayDim
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding()
                            .background(AppColor.surfaceBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .onChange(of: session.appState) {
                if case let .error(message) = session.appState {
                    errorMessage = message
                }
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            errorMessage = nil
                            session.resetState()
                        }
                    }
                ),
                presenting: errorMessage
            ) { _ in
                Button("확인", role: .cancel) {
                    errorMessage = nil
                    session.resetState()
                }
            } message: { message in
                Text(message)
            }
            .task {
                await viewModel.refreshConsultationCount(pets: session.pets)
            }
            .onChange(of: session.pets) { pets in
                Task { await viewModel.refreshConsultationCount(pets: pets) }
            }
        }
        .background(AppColor.surfaceBackground.ignoresSafeArea())
        
//        VStack {
//            NavigationView {
//                List {
//                    if let user = viewModel.user {
//                        userSection(user: user)
//                        statsSection
//                    }
//                    
//                    appInfoSection
//                    accountSection
//                    cautionSection
//                }
//                .navigationTitle("설정")
//                .alert("로그아웃", isPresented: $showingLogoutAlert) {
//                    Button("취소", role: .cancel) { }
//                    Button("로그아웃", role: .destructive) {
//                        viewModel.logout()
//                    }
//                } message: {
//                    Text("정말 로그아웃하시겠습니까?")
//                }
//                .alert("계정 삭제", isPresented: $showingDeleteAccountAlert) {
//                    Button("취소", role: .cancel) { }
//                    Button("삭제", role: .destructive) {
//                        viewModel.deleteAccount()
//                    }
//                } message: {
//                    Text("계정과 모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?")
//                }
//                .alert("이메일 복사 완료", isPresented: $showingEmailCopiedAlert) {
//                    Button("확인", role: .cancel) { }
//                } message: {
//                    Text("개발자 이메일이 클립보드에 복사되었습니다.")
//                }
//                .overlay {
//                    if session.appState == .loading {
//                        ZStack {
//                            Color.black.opacity(0.3)
//                                .ignoresSafeArea()
//                            ProgressView()
//                                .progressViewStyle(.circular)
//                                .padding()
//                                .background(Color(.systemBackground))
//                                .clipShape(RoundedRectangle(cornerRadius: 12))
//                        }
//                    }
//                }
//                .onChange(of: session.appState) {
//                    if case let .error(message) = session.appState {
//                        errorMessage = message
//                    }
//                }
//                .alert(
//                    "오류",
//                    isPresented: Binding(
//                        get: { errorMessage != nil },
//                        set: { isPresented in
//                            if !isPresented {
//                                errorMessage = nil
//                                session.resetState()
//                            }
//                        }
//                    ),
//                    presenting: errorMessage
//                ) { _ in
//                    Button("확인", role: .cancel) {
//                        errorMessage = nil
//                        session.resetState()
//                    }
//                } message: { message in
//                    Text(message)
//                }
//                .task {
//                    await viewModel.refreshConsultationCount(pets: session.pets)
//                }
//                .onChange(of: session.pets) { pets in
//                    Task { await viewModel.refreshConsultationCount(pets: pets) }
//                }
//            }
//        }
    }

    private func userSection(user: User) -> some View {
        Section("사용자 정보") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .appFont(22)
                    .foregroundStyle(AppColor.info)

                VStack(alignment: .leading) {
                    Text(user.name)
                        .appFont(17, weight: .semibold)

                    if let email = user.email {
                        Text(email)
                            .appFont(12)
                            .foregroundStyle(AppColor.subText)
                    }

                    Text("가입일: \(formattedJoinDate(user.registrationDate))")
                        .appFont(12)
                        .foregroundStyle(AppColor.subText)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    /// 사용자 정보
    private var userInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.appPeach)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                if let user = viewModel.user {
                    Text(user.name)
                        .appFont(18, weight: .medium)

                    if let email = user.email {
                        Text(email)
                            .appFont(14, weight: .light)
                            .foregroundStyle(AppColor.subText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    /// 반려동물 정보
    private var petInfo: some View {
        VStack(alignment: .leading) {
            Text("반려동물")
                .appFont(16, weight: .semibold)
                .foregroundStyle(.appWhite)
                .padding(.horizontal, 12)
                .padding(.top, 12)
            
            Divider()
                .frame(height: 1)
                .background(AppColor.surfaceBackground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            HStack {
                Text("등록된 반려동물")
                    .appFont(14, weight: .semibold)
                    .foregroundStyle(.appWhite)
                
                Spacer()
                
                Text("\(session.pets.count) 마리")
                    .appFont(14, weight: .medium)
                    .foregroundStyle(.appWhite)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            HStack {
                Text("반려동물 상담횟수")
                    .appFont(14, weight: .semibold)
                    .foregroundStyle(.appWhite)
                
                Spacer()
                
                Text("\(viewModel.consultationCount)회")
                    .appFont(14, weight: .medium)
                    .foregroundStyle(.appWhite)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.appOrange)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 20)
    }
    
    /// 앱 정보
    private var appInfo: some View {
        VStack(alignment: .leading) {
            
            HStack {
                Text("앱 버전")
                    .appFont(14)
                    .foregroundStyle(.black)
                
                Spacer()
                
                Text(appVersion)
                    .appFont(14)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            HStack {
                Text("AppStore에서 보기")
                    .appFont(14)
                    .foregroundStyle(.black)
                
                Spacer()
                if let url = viewModel.appStoreURL {
                    Link(destination: url) {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.black)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            HStack {
                Text("개발자 문의")
                    .appFont(14)
                    .foregroundStyle(.black)
                
                Spacer()
               
                Image(systemName: "chevron.right")
                    .foregroundStyle(.black)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                email.send(openURL: openURL)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            NavigationLink {
                OpenSourceLicensesView(licenses: viewModel.openSourceLicenses)
            } label: {
                HStack {
                    Text("오픈소스 라이선스")
                        .appFont(14)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColor.ink.opacity(0.7))
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(AppColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: AppColor.shadowMedium, radius: 8, x: 0, y: 0)
        .padding(.horizontal, 20)
    }
    
    /// 계정 정보
    private var appAccountInfo: some View {
        VStack {
            Button {
                showingLogoutAlert = true
            } label: {
                Text("로그아웃")
                    .appFont(16, weight: .semibold)
                    .foregroundStyle(AppColor.danger)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.orange, lineWidth: 1)
            )
            .padding(.bottom, 8)
            
            Button {
                showingDeleteAccountAlert = true
            } label: {
                Text("회원탈퇴")
                    .appFont(14, weight: .medium)
                    .foregroundStyle(AppColor.subText)
                    .underline(true, color: AppColor.subText)
            }

            
            
        }
        .padding(.horizontal, 20)
    }

    private var statsSection: some View {
        Section("반려동물 통계") {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(AppColor.success)
                Text("등록된 반려동물")
                Spacer()
                Text("\(session.pets.count)마리")
                    .foregroundStyle(AppColor.subText)
            }

            HStack {
                Image(systemName: "message.fill")
                    .foregroundStyle(AppColor.orange)
                Text("상담 횟수")
                Spacer()
                Text("\(viewModel.consultationCount)회")
                    .foregroundStyle(AppColor.subText)
            }
        }
    }
    
    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColor.info)
                Text("버전")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(AppColor.subText)
            }

            if let url = viewModel.appStoreURL {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(AppColor.info)
                        Text("앱스토어에서 보기")
                        Spacer()
                       Image(systemName: "arrow.up.right")
                           .foregroundStyle(AppColor.subText)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                    }
                }
            }

            Button {
                UIPasteboard.general.string = viewModel.developerEmail
                showingEmailCopiedAlert = true
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(AppColor.accentPurple)
                    Text("개발자 문의")
                    Spacer()
                    Text(viewModel.developerEmail)
                        .foregroundStyle(AppColor.subText)
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpenSourceLicensesView(licenses: viewModel.openSourceLicenses)
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(AppColor.info)
                    Text("오픈소스 라이선스")
                    Spacer()
                }
            }

           VStack(alignment: .leading, spacing: 2) {
               Text("© 2025 OurPet")
                    .appFont(12)
                    .foregroundStyle(AppColor.subText)
               Text("All rights reserved.")
                    .appFont(12)
                    .foregroundStyle(AppColor.subText)
           }
        }
    }

    private var accountSection: some View {
        Section("계정") {
            Button {
                showingLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(AppColor.danger)
                    Text("로그아웃")
                        .foregroundStyle(AppColor.danger)
                }
            }

            Button {
                showingDeleteAccountAlert = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .foregroundStyle(AppColor.danger)
                    Text("계정 삭제")
                        .foregroundStyle(AppColor.danger)
                }
            }
        }
    }

    private var cautionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
               HStack {
                   Image(systemName: "exclamationmark.triangle.fill")
                       .foregroundStyle(AppColor.orange)
                    Text("중요 안내")
                        .appFont(14, weight: .semibold)
                }

                Text("이 앱의 AI 상담은 참고용으로만 사용하시고, 실제 의료 진단이나 치료를 대체할 수 없습니다. 반려동물에게 응급상황이나 심각한 증상이 나타나면 즉시 동물병원에 방문해주세요.")
                    .appFont(12)
                    .foregroundStyle(AppColor.subText)
            }
            .padding(.vertical, 4)
        }
    }
}

private extension SettingsView {
    static let joinDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    func formattedJoinDate(_ date: Date) -> String {
        Self.joinDateFormatter.string(from: date)
    }
}

/// 개발자 문의 (iOS 이메일 시스템 연동)
struct SendEmailToDeveloper {
    let toAddress: String
    let subject: String
    let messageHeader: String
    var body: String {
        """
        \(messageHeader)
    --------------------------------------
    """
    }
    
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("""
                This device does not support email
                \(body)
                """)
            }
        }
    }
}
