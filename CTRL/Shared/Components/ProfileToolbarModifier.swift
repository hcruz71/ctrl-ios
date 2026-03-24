import SwiftUI

struct ProfileToolbarModifier: ViewModifier {
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingHelp = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(Color.ctrlPurple)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                    Button { showingHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
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
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
    }
}

extension View {
    func withProfileButton() -> some View {
        modifier(ProfileToolbarModifier())
    }
}
