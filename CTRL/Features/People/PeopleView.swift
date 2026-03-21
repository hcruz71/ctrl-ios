import SwiftUI

struct PeopleView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Vista", selection: $selectedTab) {
                    Text(lang.t("delegations.title")).tag(0)
                    Text(lang.t("contacts.title")).tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if selectedTab == 0 {
                    DelegationsContentView()
                } else {
                    ContactsContentView()
                }
            }
            .navigationTitle(selectedTab == 0 ? lang.t("delegations.title") : lang.t("contacts.title"))
        }
    }
}

#Preview {
    PeopleView()
}
