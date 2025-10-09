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
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var errorMessage: String?
    @State private var showingEmailCopiedAlert = false

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
            List {
                if let user = viewModel.user {
                    userSection(user: user)
                    statsSection
                }

                appInfoSection
                accountSection
                cautionSection
            }
            .navigationTitle("설정")
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
            .alert("이메일 복사 완료", isPresented: $showingEmailCopiedAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("개발자 이메일이 클립보드에 복사되었습니다.")
            }
            .overlay {
                if session.appState == .loading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding()
                            .background(Color(.systemBackground))
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
    }

    private func userSection(user: User) -> some View {
        Section("사용자 정보") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)

                    if let email = user.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Text("가입일: \(formattedJoinDate(user.registrationDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var statsSection: some View {
        Section("반려동물 통계") {
            HStack {
                Image(systemName: "pawprint.2.fill")
                    .foregroundColor(.green)
                Text("등록된 반려동물")
                Spacer()
                Text("\(session.pets.count)마리")
                    .foregroundColor(.gray)
            }

            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.orange)
                Text("상담 횟수")
                Spacer()
                Text("\(viewModel.consultationCount)회")
                    .foregroundColor(.gray)
            }
        }
    }

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("버전")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.gray)
            }

            if let url = viewModel.appStoreURL {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text("앱스토어에서 보기")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }

            Button {
                UIPasteboard.general.string = viewModel.developerEmail
                showingEmailCopiedAlert = true
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.purple)
                    Text("개발자 문의")
                    Spacer()
                    Text(viewModel.developerEmail)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                OpenSourceLicensesView(licenses: viewModel.openSourceLicenses)
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                    Text("오픈소스 라이선스")
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("© 2025 OurPet")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray)
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
                        .foregroundColor(.red)
                    Text("로그아웃")
                        .foregroundColor(.red)
                }
            }

            Button {
                showingDeleteAccountAlert = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .foregroundColor(.red)
                    Text("계정 삭제")
                        .foregroundColor(.red)
                }
            }
        }
    }

    private var cautionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("중요 안내")
                        .fontWeight(.semibold)
                }

                Text("이 앱의 AI 상담은 참고용으로만 사용하시고, 실제 의료 진단이나 치료를 대체할 수 없습니다. 반려동물에게 응급상황이나 심각한 증상이 나타나면 즉시 동물병원에 방문해주세요.")
                    .font(.caption)
                    .foregroundColor(.gray)
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
