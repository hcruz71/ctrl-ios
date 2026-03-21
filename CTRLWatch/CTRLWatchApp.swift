import SwiftUI

@main
struct CTRLWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchNavigationView()
                .environmentObject(connectivity)
        }
    }
}
