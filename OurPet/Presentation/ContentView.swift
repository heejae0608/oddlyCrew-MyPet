//
//  ContentView.swift
//  OurPet
//
//  Created by 전희재 on 9/17/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @Environment(\.diContainer) private var container
    @EnvironmentObject private var session: SessionViewModel
    @StateObject private var nativeAdLoader = NativeAdLoader.shared
    @State private var showNativeAdSheet = false
    @State private var hasRequestedNativeAd = false
    private let nativeAdFlagKey = "native_ad_popup_has_been_shown"

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
        .onChange(of: session.flow) { newFlow in
            // 화면 전환 Analytics 이벤트
            switch newFlow {
            case .splash:
                AnalyticsHelper.logEvent("flow_splash", parameters: [
                    "environment": AppEnvironment.current.rawValue
                ])
                hasRequestedNativeAd = false
                return
            case .login:
                AnalyticsHelper.logEvent("flow_login", parameters: [
                    "environment": AppEnvironment.current.rawValue
                ])
                return
            case .main:
                AnalyticsHelper.logEvent("flow_main", parameters: [
                    "environment": AppEnvironment.current.rawValue,
                    "is_logged_in": session.isLoggedIn ? "true" : "false"
                ])
            }

            guard newFlow == .main else { return }
            guard hasRequestedNativeAd == false else { return }

            hasRequestedNativeAd = true
            let defaults = UserDefaults.standard
            if defaults.object(forKey: nativeAdFlagKey) == nil {
                defaults.set(true, forKey: nativeAdFlagKey)
                defaults.synchronize()
            } else {
                showNativeAdSheet = false
                nativeAdLoader.clear()
                nativeAdLoader.load(for: .main)
            }
        }
        .onChange(of: nativeAdLoader.shouldShowAd) { showNativeAd in
            showNativeAdSheet = showNativeAd
        }
        .overlay(alignment: .center) {
            if showNativeAdSheet, nativeAdLoader.nativeAd != nil {
                NativeAdPopupView(loader: nativeAdLoader, isPresented: $showNativeAdSheet)
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
    }
}

struct MainTabView: View {
    @ObservedObject private var session: SessionViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var selectedTab = 0

    init(container: DIContainer, session: SessionViewModel) {
        _session = ObservedObject(initialValue: session)
        _chatViewModel = StateObject(wrappedValue: container.makeChatViewModel(session: session))
        _historyViewModel = StateObject(wrappedValue: container.makeHistoryViewModel(session: session))
        _settingsViewModel = StateObject(wrappedValue: container.makeSettingsViewModel(session: session))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .environmentObject(session)
                .tag(0)

            HistoryView(
                viewModel: historyViewModel,
                chatViewModel: chatViewModel,
                selectedTab: $selectedTab
            )
            .tabItem {
                Image(systemName: "clock.fill")
                Text("히스토리")
            }
            .environmentObject(session)
            .tag(1)

            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("상담")
                }
                .environmentObject(session)
                .tag(2)

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("마이")
                }
                .environmentObject(session)
                .tag(3)
        }
        .tint(AppColor.orange)
    }
}
