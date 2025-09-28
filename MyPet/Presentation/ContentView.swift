//
//  ContentView.swift
//  MyPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var session: SessionViewModel

    var body: some View {
        ZStack {
            switch session.flow {
            case .splash:
                SplashView()
            case .login:
                LoginView()
            case .main:
                MainTabView(container: container, session: session)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: session.flow)
    }
}

struct MainTabView: View {
    @ObservedObject private var session: SessionViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(container: DIContainer, session: SessionViewModel) {
        _session = ObservedObject(initialValue: session)
        _chatViewModel = StateObject(wrappedValue: container.makeChatViewModel(session: session))
        _historyViewModel = StateObject(wrappedValue: container.makeHistoryViewModel(session: session))
        _settingsViewModel = StateObject(wrappedValue: container.makeSettingsViewModel(session: session))
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .environmentObject(session)

            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("히스토리")
                }
                .environmentObject(session)

            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("상담")
                }
                .environmentObject(session)

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .environmentObject(session)
        }
        .tint(AppColor.orange)
    }
}
