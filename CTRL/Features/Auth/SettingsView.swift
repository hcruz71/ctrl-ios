import SwiftUI
import AuthenticationServices

private class OAuthCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var pushManager = PushManager.shared

    @State private var googleAccounts: [GoogleCalendarAccount] = []
    @State private var gcalLoading = false
    @State private var accountToDelete: GoogleCalendarAccount?
    @State private var oauthCoordinator = OAuthCoordinator()
    @State private var currentMode: WorkMode?
    @State private var trashCount = 0

    var body: some View {
        List {
            // MARK: - Calendario
            Section(lang.t("settings.calendar")) {
                if gcalLoading && googleAccounts.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }

                ForEach(googleAccounts) { account in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(String(account.email.prefix(1)).uppercased())
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.blue)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.label ?? account.email)
                                .font(.subheadline).fontWeight(.medium)
                            if account.label != nil {
                                Text(account.email)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: account.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundStyle(account.isActive ? .green : .secondary)
                            .font(.caption)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { accountToDelete = account } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        Button {
                            Task { await toggleAccountActive(account) }
                        } label: {
                            Label(account.isActive ? "Pausar" : "Activar",
                                  systemImage: account.isActive ? "pause" : "play")
                        }
                        .tint(account.isActive ? .orange : .green)
                    }
                }

                Button { startGoogleOAuth() } label: {
                    Label("Agregar cuenta de Google", systemImage: "plus.circle")
                }

                if !googleAccounts.isEmpty {
                    Button {
                        Task {
                            gcalLoading = true
                            struct R: Codable { let created: Int; let updated: Int }
                            let _: R? = try? await APIClient.shared.request(.googleCalendarSync)
                            await loadGoogleAccounts()
                            gcalLoading = false
                        }
                    } label: {
                        Label(gcalLoading ? "Sincronizando..." : "Sincronizar todas",
                              systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(gcalLoading)
                }
            }
            .alert("Desconectar cuenta", isPresented: .init(
                get: { accountToDelete != nil },
                set: { if !$0 { accountToDelete = nil } }
            )) {
                Button("Cancelar", role: .cancel) { accountToDelete = nil }
                Button("Desconectar", role: .destructive) {
                    if let account = accountToDelete {
                        Task { await deleteAccount(account) }
                    }
                }
            } message: {
                Text("Se desconectara \(accountToDelete?.email ?? "") de VERA.")
            }

            // MARK: - Tiempo y Disponibilidad
            Section(lang.t("settings.schedule")) {
                NavigationLink {
                    ScheduleSettingsView()
                } label: {
                    HStack {
                        Label(lang.t("profile.schedule"), systemImage: "clock")
                        Spacer()
                        if let mode = currentMode {
                            Text(mode.label)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(modeColor(mode).opacity(0.15))
                                .foregroundStyle(modeColor(mode))
                                .clipShape(Capsule())
                        }
                    }
                }

                NavigationLink {
                    AbsencesListView()
                } label: {
                    Label(lang.t("settings.absences"), systemImage: "sun.max")
                }
            }

            // MARK: - Sistema
            Section(lang.t("settings.notifications")) {
                NavigationLink {
                    NotificationPreferencesView()
                } label: {
                    HStack {
                        Label(lang.t("profile.notifications"), systemImage: "bell.fill")
                        Spacer()
                        Text(permissionLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    UsageView()
                } label: {
                    Label(lang.t("settings.usage"), systemImage: "chart.bar.fill")
                }

                NavigationLink {
                    TrashView()
                } label: {
                    HStack {
                        Label(lang.t("trash.title"), systemImage: "trash")
                        Spacer()
                        if trashCount > 0 {
                            Text("\(trashCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationTitle(lang.t("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await pushManager.refreshPermissionStatus()
            await loadGoogleAccounts()
            await loadCurrentMode()
            await loadTrashCount()
        }
    }

    // MARK: - Helpers

    private func startGoogleOAuth() {
        guard let token = authManager.token,
              let url = URL(string: "\(APIEndpoint.baseURL)/google-calendar/auth?token=\(token)") else {
            return
        }
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "ctrl") { _, _ in
            Task { await loadGoogleAccounts() }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = oauthCoordinator
        session.start()
    }

    private func loadGoogleAccounts() async {
        gcalLoading = true
        do {
            googleAccounts = try await APIClient.shared.request(.googleCalendarAccounts)
        } catch {
            googleAccounts = []
        }
        gcalLoading = false
    }

    private func toggleAccountActive(_ account: GoogleCalendarAccount) async {
        let body = UpdateGoogleCalendarBody(isActive: !account.isActive)
        do {
            let _: GoogleCalendarAccount = try await APIClient.shared.request(
                .googleCalendarAccount(id: account.id), method: "PATCH", body: body)
            await loadGoogleAccounts()
        } catch { }
    }

    private func deleteAccount(_ account: GoogleCalendarAccount) async {
        do {
            try await APIClient.shared.requestVoid(.googleCalendarAccount(id: account.id), method: "DELETE")
        } catch { }
        accountToDelete = nil
        await loadGoogleAccounts()
    }

    private func loadCurrentMode() async {
        do {
            let response: WorkModeResponse = try await APIClient.shared.request(.scheduleMode)
            currentMode = response.mode
        } catch {
            currentMode = .work
        }
    }

    private func modeColor(_ mode: WorkMode) -> Color {
        switch mode {
        case .work:     return .blue
        case .personal: return .green
        case .rest:     return .gray
        case .vacation: return .orange
        }
    }

    private func loadTrashCount() async {
        let tasks: [CTRLTask] = (try? await APIClient.shared.request(.tasksTrash)) ?? []
        let projects: [Project] = (try? await APIClient.shared.request(.projectsTrash)) ?? []
        let objectives: [Objective] = (try? await APIClient.shared.request(.objectivesTrash)) ?? []
        trashCount = tasks.count + projects.count + objectives.count
    }

    private var permissionLabel: String {
        switch pushManager.permissionStatus {
        case .authorized:     return "Activadas"
        case .denied:         return "Denegadas"
        case .provisional:    return "Provisional"
        case .ephemeral:      return "Temporal"
        case .notDetermined:  return "Sin configurar"
        @unknown default:     return "Desconocido"
        }
    }
}
