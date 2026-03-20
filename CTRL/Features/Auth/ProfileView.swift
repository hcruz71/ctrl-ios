import SwiftUI
import UserNotifications
import AVFoundation
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var pushManager = PushManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false

    @State private var assistantName: String = ""
    @State private var assistantPersonality: String = "ejecutivo"
    @State private var assistantVoice: String = "es-MX-female"
    @State private var isSaving = false
    @State private var previewSynthesizer = AVSpeechSynthesizer()
    @State private var gcalConnected = false
    @State private var gcalLoading = false

    private let personalities: [(id: String, icon: String, label: String, desc: String)] = [
        ("ejecutivo", "🎯", "Ejecutivo", "Directo, conciso, orientado a resultados"),
        ("coach", "🤝", "Coach", "Motivador, empático, da contexto adicional"),
        ("analitico", "🧠", "Analítico", "Detallado, incluye métricas y datos"),
        ("amigable", "😊", "Amigable", "Casual, usa emojis, tono conversacional"),
    ]

    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    Section {
                        Label(user.name, systemImage: "person.fill")
                        Label(user.email, systemImage: "envelope.fill")
                    }
                }

                Section("Mi Asistente") {
                    HStack {
                        Label("Nombre", systemImage: "sparkles")
                        Spacer()
                        TextField("CTRL", text: $assistantName)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 160)
                    }

                    ForEach(personalities, id: \.id) { p in
                        Button {
                            withAnimation { assistantPersonality = p.id }
                        } label: {
                            HStack(spacing: 12) {
                                Text(p.icon)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.label)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(p.desc)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if assistantPersonality == p.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }
                    }

                    Button {
                        Task { await saveAssistantSettings() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Guardar cambios")
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }

                Section("Voz del Asistente") {
                    ForEach(AssistantViewModel.voiceConfigs) { vc in
                        let available = isVoiceAvailable(vc)
                        Button {
                            withAnimation { assistantVoice = vc.id }
                        } label: {
                            HStack(spacing: 12) {
                                Text(vc.flag)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vc.label)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    if !available {
                                        Text("Descargar en Ajustes → Accesibilidad → Contenido leído")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                                Button {
                                    previewVoice(vc)
                                } label: {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                                .buttonStyle(.plain)
                                if assistantVoice == vc.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }
                    }
                }

                Section("Google Calendar") {
                    HStack {
                        Label("Estado", systemImage: "calendar.badge.clock")
                        Spacer()
                        if gcalLoading {
                            ProgressView()
                        } else {
                            Text(gcalConnected ? "Conectado" : "No conectado")
                                .foregroundStyle(gcalConnected ? .green : .secondary)
                        }
                    }

                    if !gcalConnected {
                        Button {
                            startGoogleOAuth()
                        } label: {
                            Label("Conectar Google Calendar", systemImage: "link")
                        }
                    } else {
                        Button {
                            Task {
                                gcalLoading = true
                                struct SyncResult: Codable {
                                    let created: Int
                                    let updated: Int
                                }
                                do {
                                    let _: SyncResult = try await APIClient.shared.request(.googleCalendarSync)
                                } catch { }
                                gcalLoading = false
                            }
                        } label: {
                            Label("Sincronizar ahora", systemImage: "arrow.triangle.2.circlepath")
                        }
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

                    #if DEBUG
                    Button {
                        pushManager.sendLocalNotification(
                            title: "CTRL — Test local",
                            body: "Deep linking y UI funcionan correctamente.",
                            data: ["type": "delegation:overdue"]
                        )
                    } label: {
                        Label("Enviar notificación local", systemImage: "arrow.up.message.fill")
                    }
                    #endif
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
                loadAssistantSettings()
                await checkGoogleCalendar()
            }
        }
    }

    // MARK: - Helpers

    private func loadAssistantSettings() {
        assistantName = UserDefaults.standard.string(forKey: "assistantName")
            ?? authManager.currentUser?.assistantName
            ?? "CTRL"
        assistantPersonality = UserDefaults.standard.string(forKey: "assistantPersonality")
            ?? authManager.currentUser?.assistantPersonality
            ?? "ejecutivo"
        assistantVoice = UserDefaults.standard.string(forKey: "assistantVoice")
            ?? authManager.currentUser?.assistantVoice
            ?? "es-MX-female"
    }

    private func saveAssistantSettings() async {
        isSaving = true
        let name = assistantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? "CTRL" : name

        UserDefaults.standard.set(finalName, forKey: "assistantName")
        UserDefaults.standard.set(assistantPersonality, forKey: "assistantPersonality")
        UserDefaults.standard.set(assistantVoice, forKey: "assistantVoice")

        let body = UpdateUserBody(
            assistantName: finalName,
            assistantPersonality: assistantPersonality,
            assistantVoice: assistantVoice
        )
        do {
            let _: User = try await APIClient.shared.request(.updateMe, method: "PATCH", body: body)
            await authManager.fetchProfile()
        } catch {
            // Saved locally regardless
        }
        isSaving = false
    }

    private func isVoiceAvailable(_ vc: AssistantViewModel.VoiceConfig) -> Bool {
        if let id = vc.identifier,
           AVSpeechSynthesisVoice(identifier: id) != nil {
            return true
        }
        return AVSpeechSynthesisVoice.speechVoices().contains {
            $0.language == vc.language && $0.name.localizedCaseInsensitiveContains(vc.namePrefix)
        }
    }

    private func previewVoice(_ vc: AssistantViewModel.VoiceConfig) {
        previewSynthesizer.stopSpeaking(at: .immediate)
        let sampleText = vc.language.hasPrefix("en")
            ? "Hi, I'm your CTRL assistant"
            : "Hola, soy tu asistente CTRL"
        let utterance = AVSpeechUtterance(string: sampleText)

        if let id = vc.identifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: id)
        }
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: vc.language)
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        previewSynthesizer.speak(utterance)
    }

    private func startGoogleOAuth() {
        guard let token = authManager.token,
              let url = URL(string: "\(APIEndpoint.baseURL)/google-calendar/auth?token=\(token)") else {
            return
        }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil
        ) { _, _ in
            // Google redirects to our backend callback which shows an HTML success page.
            // When the user closes the sheet, refresh the connection status.
            Task { await checkGoogleCalendar() }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = nil
        session.start()
    }

    private func checkGoogleCalendar() async {
        struct Status: Codable { let connected: Bool }
        gcalLoading = true
        do {
            let status: Status = try await APIClient.shared.request(.googleCalendarStatus)
            gcalConnected = status.connected
        } catch {
            gcalConnected = false
        }
        gcalLoading = false
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
