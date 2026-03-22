import SwiftUI

struct DayPlanView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Vista", selection: $selectedTab) {
                Text(lang.t("tab.meetings")).tag(0)
                Text(lang.t("contacts.title")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedTab == 0 {
                MeetingsView()
            } else {
                NavigationStack {
                    ContactsContentView()
                        .navigationTitle(lang.t("contacts.title"))
                        .withProfileButton()
                }
            }
        }
    }
}
