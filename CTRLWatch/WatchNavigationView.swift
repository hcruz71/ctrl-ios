import SwiftUI

struct WatchNavigationView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchMainView()
                .tag(0)
            WatchTasksView()
                .tag(1)
            WatchMeetingsView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
    }
}
