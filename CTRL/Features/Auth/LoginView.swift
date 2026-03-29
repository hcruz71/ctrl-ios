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

// MARK: - Color palette

private extension Color {
    static let bgDark = Color(hex: "#0D1B2A")
    static let surface = Color(hex: "#132235")
    static let borderField = Color(hex: "#1A3A6E")
    static let electricBlue = Color(hex: "#1A6EDB")
    static let textSecondary = Color(hex: "#7A96B8")
    static let textPlaceholder = Color(hex: "#4A6480")
}

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @State private var googleOAuthCoordinator = GoogleOAuthCoordinator()
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Color.bgDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: - Header
                    Image("VERALogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.top, 60)
                        .padding(.bottom, 32)

                    Text("VIRTUAL  ·  EXECUTIVE  ·  RESOURCE  ·  ASSISTANT")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#7A96B8"))
                        .kerning(2.5)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.top, -16)
                        .padding(.bottom, 24)

                    // MARK: - Fields
                    VStack(spacing: 14) {
                        if vm.isRegistering {
                            customField(
                                icon: "person.fill",
                                placeholder: "Nombre",
                                text: $vm.name,
                                contentType: .name
                            )
                        }

                        customField(
                            icon: "envelope.fill",
                            placeholder: "Correo electrónico",
                            text: $vm.email,
                            contentType: .emailAddress,
                            keyboard: .emailAddress,
                            autocap: .never
                        )

                        // Password field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.textSecondary)
                                .frame(width: 20)

                            Group {
                                if showPassword {
                                    TextField("Contraseña", text: $vm.password)
                                } else {
                                    SecureField("Contraseña", text: $vm.password)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .textContentType(vm.isRegistering ? .newPassword : .password)
                            .tint(.electricBlue)

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.borderField, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    // Forgot password
                    if !vm.isRegistering {
                        HStack {
                            Spacer()
                            Button {
                                // TODO: forgot password
                            } label: {
                                Text("¿Olvidaste tu contraseña?")
                                    .font(.system(size: 12))
                                    .foregroundColor(.electricBlue)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }

                    // MARK: - Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    // MARK: - Primary button
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
                                Text(vm.isRegistering ? "Registrarse" : "Iniciar sesión")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.electricBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // MARK: - Divider
                    HStack(spacing: 12) {
                        Rectangle().frame(height: 1).foregroundColor(Color.borderField)
                        Text("o continúa con")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .layoutPriority(1)
                        Rectangle().frame(height: 1).foregroundColor(Color.borderField)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                    // MARK: - Social buttons
                    VStack(spacing: 12) {
                        // Apple
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Google
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 22, height: 22)
                                    Text("G")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                Text("Continuar con Google")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "#1C2126"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)

                    // MARK: - Toggle register/login
                    Button {
                        withAnimation { vm.isRegistering.toggle() }
                    } label: {
                        Group {
                            if vm.isRegistering {
                                Text("¿Ya tienes cuenta? ") +
                                Text("Inicia sesión").bold()
                            } else {
                                Text("¿No tienes cuenta? ") +
                                Text("Regístrate").bold()
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 32)
                }
            }
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

    // MARK: - Custom text field

    private func customField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default,
        autocap: TextInputAutocapitalization = .sentences
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.textSecondary)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .tint(.electricBlue)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderField, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
