import SwiftUI
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var pushManager = PushManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    Section {
                        Label(user.name, systemImage: "person.fill")
                        Label(user.email, systemImage: "envelope.fill")
                    }
                }

                Section("Notificaciones") {
                    HStack {
                        Label("Estado", systemImage: "bell.fill")
                        Spacer()
                        Text(permissionLabel)
                            .foregroundStyle(.secondary)
                    }

                    if pushManager.permissionStatus == .notDetermined {
                        Button {
                            Task { await pushManager.requestPermissionAndRegister() }
                        } label: {
                            Label("Activar notificaciones", systemImage: "bell.badge")
                        }
                    } else if pushManager.permissionStatus == .denied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Abrir Ajustes para activar", systemImage: "gear")
                        }
                    }

                    if let token = pushManager.deviceToken {
                        HStack {
                            Label("Token", systemImage: "key.fill")
                            Spacer()
                            Text(token.prefix(12) + "…")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                        dismiss()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                await pushManager.refreshPermissionStatus()
            }
        }
    }

    private var permissionLabel: String {
        switch pushManager.permissionStatus {
        case .authorized: return "Activadas"
        case .denied: return "Denegadas"
        case .provisional: return "Provisional"
        case .ephemeral: return "Temporal"
        case .notDetermined: return "Sin configurar"
        @unknown default: return "Desconocido"
        }
    }
}
