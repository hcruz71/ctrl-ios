import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("Cargando sesión…")
            } else if authManager.isAuthenticated {
                CTRLTabView(selectedTab: $navigationState.selectedTab)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(NavigationState.shared)
}
