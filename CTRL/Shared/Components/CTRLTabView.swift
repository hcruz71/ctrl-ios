import SwiftUI

struct CTRLTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var delegationsVM = DelegationsViewModel()
    @StateObject private var tasksVM = TasksViewModel()
    @State private var showingQuickCapture = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                ObjectivesView()
                    .tabItem {
                        Label(lang.t("tab.objectives"), systemImage: "target")
                    }
                    .tag(0)

                MeetingsView()
                    .tabItem {
                        Label(lang.t("tab.meetings"), systemImage: "calendar")
                    }
                    .tag(1)

                AssistantView()
                    .tabItem {
                        Label(lang.t("tab.assistant"), systemImage: "sparkles")
                    }
                    .tag(2)

                TasksView()
                    .tabItem {
                        Label(lang.t("tab.tasks"), systemImage: "checkmark.circle")
                    }
                    .tag(3)

                PeopleView()
                    .tabItem {
                        Label(lang.t("tab.people"), systemImage: "person.2")
                    }
                    .badge(delegationsVM.pendingCount)
                    .tag(4)
            }
            .tint(Color.ctrlPurple)

            // FAB — bottom-right, above tab bar
            Button {
                showingQuickCapture = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.ctrlPurple)
                    .clipShape(Circle())
                    .shadow(color: .ctrlPurple.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 64)
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView { body in
                Task { await tasksVM.create(body) }
            }
        }
        .task { await delegationsVM.fetchDelegations() }
    }
}

#Preview {
    CTRLTabView(selectedTab: .constant(2))
}
