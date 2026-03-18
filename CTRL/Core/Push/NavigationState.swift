import Foundation

/// Shared navigation state for deep linking from push notifications.
@MainActor
final class NavigationState: ObservableObject {
    static let shared = NavigationState()

    @Published var selectedTab: Int = 0

    private init() {}
}
