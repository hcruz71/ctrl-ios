import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("CTRL")
                            .font(.system(size: 48, weight: .black))
                            .foregroundStyle(Color.ctrlPurple)
                        Text(vm.isRegistering ? "Crea tu cuenta" : "Inicia sesión")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)

                    // Fields
                    VStack(spacing: 16) {
                        if vm.isRegistering {
                            TextField("Nombre", text: $vm.name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                        }

                        TextField("Email", text: $vm.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Contraseña", text: $vm.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(vm.isRegistering ? .newPassword : .password)
                    }
                    .padding(.horizontal)

                    // Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Primary button
                    Button {
                        Task {
                            if vm.isRegistering {
                                await vm.register()
                            } else {
                                await vm.login()
                            }
                        }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(vm.isRegistering ? "Registrarse" : "Entrar")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ctrlPurple)
                    .padding(.horizontal)
                    .disabled(vm.isLoading)

                    // Toggle register/login
                    Button {
                        withAnimation { vm.isRegistering.toggle() }
                    } label: {
                        Text(vm.isRegistering
                             ? "¿Ya tienes cuenta? Inicia sesión"
                             : "¿No tienes cuenta? Regístrate")
                            .font(.footnote)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    LoginView()
}
