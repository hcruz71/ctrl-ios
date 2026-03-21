import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isRegistering = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Completa todos los campos."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await AuthManager.shared.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register() async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Completa todos los campos."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await AuthManager.shared.register(name: name, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Social Auth

    func loginWithApple(identityToken: String, fullName: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            struct AppleBody: Encodable {
                let identityToken: String
                let fullName: String?
            }
            let body = AppleBody(identityToken: identityToken, fullName: fullName)
            let result: AuthResponse = try await APIClient.shared.request(.loginApple, body: body)
            await AuthManager.shared.handleAuthResponse(token: result.token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loginWithGoogle(idToken: String) async {
        isLoading = true
        errorMessage = nil
        do {
            struct GoogleBody: Encodable {
                let idToken: String
            }
            let body = GoogleBody(idToken: idToken)
            let result: AuthResponse = try await APIClient.shared.request(.loginGoogle, body: body)
            await AuthManager.shared.handleAuthResponse(token: result.token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
