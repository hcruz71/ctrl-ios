import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var lang: LanguageManager
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView(lang.t("loading.session"))
            } else if authManager.isAuthenticated {
                CTRLTabView(selectedTab: $navigationState.selectedTab)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .onChange(of: authManager.currentUser?.onboardingCompleted) { completed in
            if authManager.isAuthenticated && completed != true {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(NavigationState.shared)
}
