import SwiftUI

struct DayPlanView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Vista", selection: $selectedTab) {
                Text(lang.t("tab.meetings")).tag(0)
                Text("Correos").tag(1)
                Text(lang.t("contacts.title")).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case 0:
                MeetingsView()
            case 1:
                NavigationStack {
                    EmailAnalysisView()
                }
            default:
                NavigationStack {
                    ContactsContentView()
                        .navigationTitle(lang.t("contacts.title"))
                        .withProfileButton()
                }
            }
        }
    }
}
