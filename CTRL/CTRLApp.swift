import SwiftUI

@main
struct CTRLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var navigationState = NavigationState.shared
    @StateObject private var lang = LanguageManager.shared
    @StateObject private var store = StoreManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(navigationState)
                .environmentObject(lang)
                .environmentObject(store)
                .task { await store.listenForTransactions() }
                .task { await store.checkCurrentEntitlements() }
        }
    }
}
