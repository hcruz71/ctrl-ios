import SwiftUI

struct PeopleView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Vista", selection: $selectedTab) {
                    Text("Delegaciones").tag(0)
                    Text("Contactos").tag(1)
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
            .navigationTitle(selectedTab == 0 ? "Delegaciones" : "Contactos")
        }
    }
}

#Preview {
    PeopleView()
}
