import SwiftUI

struct ProfileToolbarModifier: ViewModifier {
    @State private var showingProfile = false
    @State private var showingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(Color.ctrlPurple)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
    }
}

extension View {
    func withProfileButton() -> some View {
        modifier(ProfileToolbarModifier())
    }
}
