import SwiftUI

struct ProfileToolbarModifier: ViewModifier {
    @State private var showingProfile = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingProfile = true } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(Color.ctrlPurple)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
    }
}

extension View {
    func withProfileButton() -> some View {
        modifier(ProfileToolbarModifier())
    }
}
