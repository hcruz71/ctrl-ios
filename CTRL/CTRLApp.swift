import SwiftUI

@main
struct CTRLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var navigationState = NavigationState.shared
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var store = StoreManager.shared
    @State private var isShowingLaunch = true

    init() {
        WatchBridge.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(navigationState)
                    .environmentObject(lang)
                    .environmentObject(store)
                    .task { await store.listenForTransactions() }
                    .task { await store.checkCurrentEntitlements() }

                if isShowingLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    isShowingLaunch = false
                                }
                            }
                        }
                }
            }
        }
    }
}
