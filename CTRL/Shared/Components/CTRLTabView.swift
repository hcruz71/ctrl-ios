import SwiftUI

struct CTRLTabView: View {
    @Binding var selectedTab: Int
    @StateObject private var delegationsVM = DelegationsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            ObjectivesView()
                .tabItem {
                    Label("Objetivos", systemImage: "target")
                }
                .tag(0)

            MeetingsView()
                .tabItem {
                    Label("Reuniones", systemImage: "calendar")
                }
                .tag(1)

            TasksView()
                .tabItem {
                    Label("Tareas", systemImage: "checkmark.circle")
                }
                .tag(2)

            DelegationsView()
                .tabItem {
                    Label("Delegaciones", systemImage: "person.2")
                }
                .badge(delegationsVM.pendingCount)
                .tag(3)

            ContactsView()
                .tabItem {
                    Label("Contactos", systemImage: "person.crop.circle")
                }
                .tag(4)

            AssistantView()
                .tabItem {
                    Label("Asistente", systemImage: "sparkles")
                }
                .tag(5)
        }
        .tint(Color.ctrlPurple)
        .task { await delegationsVM.fetchDelegations() }
    }
}

#Preview {
    CTRLTabView(selectedTab: .constant(0))
}
