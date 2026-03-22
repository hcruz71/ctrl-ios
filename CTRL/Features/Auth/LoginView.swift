import SwiftUI
import AuthenticationServices

private class GoogleOAuthCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @State private var googleOAuthCoordinator = GoogleOAuthCoordinator()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // HEADER
                VStack(spacing: 8) {
                    Image("CTRLLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("CTRL")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(Color.ctrlPurple)

                    Text("Control  ·  Tareas  ·  Reuniones  ·  Liderazgo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .kerning(0.5)
                }
                .padding(.top, 48)

                // FIELDS
                VStack(spacing: 14) {
                    if vm.isRegistering {
                        TextField("Nombre", text: $vm.name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }

                    TextField("Correo electronico", text: $vm.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Contrasena", text: $vm.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(vm.isRegistering ? .newPassword : .password)
                }

                // ERROR
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // PRIMARY BUTTON
                Button {
                    Task {
                        if vm.isRegistering { await vm.register() }
                        else { await vm.login() }
                    }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.isRegistering ? "Registrarse" : "Iniciar sesion")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ctrlPurple)
                .disabled(vm.isLoading)

                // SEPARATOR
                HStack(spacing: 12) {
                    Rectangle().frame(height: 1).foregroundStyle(.gray.opacity(0.3))
                    Text("o continua con")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .layoutPriority(1)
                    Rectangle().frame(height: 1).foregroundStyle(.gray.opacity(0.3))
                }

                // SOCIAL BUTTONS
                VStack(spacing: 12) {
                    // Google
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                Text("G")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                            Text("Continuar con Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Apple (native)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // TOGGLE
                Button {
                    withAnimation { vm.isRegistering.toggle() }
                } label: {
                    Text(vm.isRegistering
                         ? "Ya tienes cuenta? Inicia sesion"
                         : "No tienes cuenta? Registrate")
                        .font(.footnote)
                        .foregroundStyle(Color.ctrlPurple)
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Google Sign In via OAuth

    private func signInWithGoogle() {
        guard let url = URL(string: "\(APIEndpoint.baseURL)/auth/google") else { return }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "ctrl"
        ) { callbackURL, error in
            guard error == nil,
                  let callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "token" })?.value
            else {
                if let err = error as NSError?, err.code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    vm.errorMessage = "Error de Google Sign In"
                }
                return
            }
            Task { await vm.handleGoogleOAuthToken(token) }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = googleOAuthCoordinator
        session.start()
    }

    // MARK: - Apple Sign In Handler

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                vm.errorMessage = "Error al obtener credenciales de Apple"
                return
            }

            var fullName: String?
            if let given = credential.fullName?.givenName,
               let family = credential.fullName?.familyName {
                fullName = "\(given) \(family)"
            }

            Task { await vm.loginWithApple(identityToken: identityToken, fullName: fullName) }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                vm.errorMessage = "Error de Apple Sign In"
            }
        }
    }
}

#Preview {
    LoginView()
}
