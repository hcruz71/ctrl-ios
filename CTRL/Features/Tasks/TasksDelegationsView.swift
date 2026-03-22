import SwiftUI

struct TasksDelegationsView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Vista", selection: $selectedTab) {
                Text(lang.t("tab.tasks")).tag(0)
                Text(lang.t("delegations.title")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedTab == 0 {
                TasksView()
            } else {
                NavigationStack {
                    DelegationsContentView()
                        .navigationTitle(lang.t("delegations.title"))
                        .withProfileButton()
                }
            }
        }
    }
}
