import SwiftUI

@main
struct CTRLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var navigationState = NavigationState.shared
    @StateObject private var lang = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(navigationState)
                .environmentObject(lang)
        }
    }
}
