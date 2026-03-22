import Foundation

/// Manages authentication state across the app.
/// Persists JWT in Keychain and exposes the current user.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    var token: String? {
        KeychainHelper.getToken()
    }

    private init() {
        if KeychainHelper.getToken() != nil {
            isAuthenticated = true
            isLoading = true
            Task { await restoreSession() }
        }
    }

    /// Restores the user session from the persisted JWT on app launch.
    private func restoreSession() async {
        await fetchProfile()
        isLoading = false
        if isAuthenticated {
            await PushManager.shared.requestPermissionAndRegister()
        }
    }

    // MARK: - Auth actions

    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let body = LoginBody(email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.request(.login, body: body)

        KeychainHelper.saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true
        await PushManager.shared.requestPermissionAndRegister()
    }

    func register(name: String, email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let body = RegisterBody(name: name, email: email, password: password)
        let response: AuthResponse = try await APIClient.shared.request(.register, body: body)

        KeychainHelper.saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true
        await PushManager.shared.requestPermissionAndRegister()
    }

    /// Handles a token received from social auth (Apple / Google).
    func handleAuthResponse(token: String) async {
        isLoading = true
        defer { isLoading = false }
        KeychainHelper.saveToken(token)
        isAuthenticated = true
        await fetchProfile()
        await PushManager.shared.requestPermissionAndRegister()
    }

    func fetchProfile() async {
        do {
            currentUser = try await APIClient.shared.request(.me)
            isAuthenticated = true
            // Sync StoreManager with the backend plan so all views agree
            if let planStr = currentUser?.plan,
               let plan = SubscriptionPlan(rawValue: planStr) {
                StoreManager.shared.currentPlan = plan
            }
        } catch {
            if let apiError = error as? APIError, apiError.isUnauthorized {
                logout()
            }
        }
    }

    func logout() {
        // Revoke MCP tokens on the backend before clearing local state
        Task {
            try? await APIClient.shared.requestVoid(.revokeMcpToken)
        }
        KeychainHelper.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - Request / Response bodies

private struct LoginBody: Encodable {
    let email: String
    let password: String
}

private struct RegisterBody: Encodable {
    let name: String
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}
