//
//  SettingsView.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingLogoutAlert = false
    @State private var showingDeleteDataAlert = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                if let user = viewModel.user {
                    userSection(user: user)
                    statsSection
                }

                appInfoSection
                dataSection
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
            .alert("데이터 삭제", isPresented: $showingDeleteDataAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("모든 반려동물 정보와 상담 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
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

                    Text("가입일: \(user.registrationDate, style: .date)")
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

        }
    }

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("버전")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.gray)
            }

            HStack {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.blue)
                Text("도움말")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }

    private var dataSection: some View {
        Section("데이터 관리") {
            Button {
                showingDeleteDataAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("모든 데이터 삭제")
                        .foregroundColor(.red)
                }
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
