import SwiftUI
import UserNotifications
import AVFoundation
import AuthenticationServices

// MARK: - OAuth Presentation Coordinator

private class OAuthCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var pushManager = PushManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false

    @State private var assistantName: String = ""
    @State private var assistantPersonality: String = "ejecutivo"
    @State private var assistantVoice: String = "es-MX-female"
    @State private var isSaving = false
    @State private var previewSynthesizer = AVSpeechSynthesizer()
    @State private var googleAccounts: [GoogleCalendarAccount] = []
    @State private var gcalLoading = false
    @State private var accountToDelete: GoogleCalendarAccount?
    @State private var oauthCoordinator = OAuthCoordinator()
    @State private var currentMode: WorkMode?

    // MARK: Collapsible section state
    @AppStorage("profile.section.assistant") private var expandedAssistant = true
    @AppStorage("profile.section.voice") private var expandedVoice = false
    @AppStorage("profile.section.gcal") private var expandedGCal = true
    @AppStorage("profile.section.schedule") private var expandedSchedule = false
    @AppStorage("profile.section.notifications") private var expandedNotifications = false
    @AppStorage("profile.section.language") private var expandedLanguage = true
    @State private var selectedLanguage: String = LanguageManager.shared.currentLanguage
    @State private var showLanguageRestart = false

    private let personalities: [(id: String, icon: String, label: String, desc: String)] = [
        ("ejecutivo", "🎯", "Ejecutivo", "Directo, conciso, orientado a resultados"),
        ("coach", "🤝", "Coach", "Motivador, empático, da contexto adicional"),
        ("analitico", "🧠", "Analítico", "Detallado, incluye métricas y datos"),
        ("amigable", "😊", "Amigable", "Casual, usa emojis, tono conversacional"),
    ]

    // MARK: - Voice helpers

    private var voicesForSelectedLanguage: [AssistantViewModel.VoiceConfig] {
        AssistantViewModel.voiceConfigs.filter { $0.langGroup == selectedLanguage }
    }

    private func onLanguageChanged(to code: String) {
        LanguageManager.shared.currentLanguage = code
        showLanguageRestart = true
        // Auto-switch voice if current voice doesn't match new language
        let currentVoiceLang = AssistantViewModel.voiceConfigs.first { $0.id == assistantVoice }?.langGroup
        if currentVoiceLang != code {
            if let firstVoice = AssistantViewModel.voiceConfigs.first(where: { $0.langGroup == code }) {
                assistantVoice = firstVoice.id
                UserDefaults.standard.set(firstVoice.id, forKey: "assistantVoice")
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 1. User info — always visible
                if let user = authManager.currentUser {
                    Section {
                        Label(user.name, systemImage: "person.fill")
                        Label(user.email, systemImage: "envelope.fill")
                    }
                }

                // 2. Mi Asistente — collapsible, default expanded
                collapsibleSection(title: lang.t("profile.assistant"), icon: "sparkles", expanded: $expandedAssistant) {
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
                                Text(lang.t("profile.saveChanges"))
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }

                // 3. Voz del Asistente — only voices for selected language
                collapsibleSection(title: lang.t("profile.voice"), icon: "waveform", expanded: $expandedVoice) {
                    ForEach(voicesForSelectedLanguage) { vc in
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
                                        Text("Descargar en Ajustes → Accesibilidad → Contenido leido")
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

                // 4. Idioma — collapsible, default expanded (NEW)
                collapsibleSection(title: lang.t("profile.language"), icon: "globe", expanded: $expandedLanguage) {
                    ForEach(LanguageManager.supportedLanguages, id: \.code) { lang in
                        Button {
                            selectedLanguage = lang.code
                            onLanguageChanged(to: lang.code)
                        } label: {
                            HStack(spacing: 12) {
                                Text(lang.flag)
                                    .font(.title3)
                                Text(lang.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedLanguage == lang.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }
                    }
                    if showLanguageRestart {
                        Label("Reinicia la app para aplicar el idioma", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // 5. Google Calendar — collapsible, default expanded
                collapsibleSection(title: "Google Calendar", icon: "calendar.badge.checkmark", expanded: $expandedGCal) {
                    if gcalLoading && googleAccounts.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
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
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if account.label != nil {
                                    Text(account.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if account.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            } else {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                accountToDelete = account
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }

                            Button {
                                Task { await toggleAccountActive(account) }
                            } label: {
                                Label(
                                    account.isActive ? "Pausar" : "Activar",
                                    systemImage: account.isActive ? "pause" : "play"
                                )
                            }
                            .tint(account.isActive ? .orange : .green)
                        }
                    }

                    Button {
                        startGoogleOAuth()
                    } label: {
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
                            Label(
                                gcalLoading ? "Sincronizando..." : "Sincronizar todas",
                                systemImage: "arrow.triangle.2.circlepath"
                            )
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
                    Text("Se desconectará \(accountToDelete?.email ?? "") de CTRL. Las reuniones importadas se conservan.")
                }

                // 6. Horario y modos — collapsible, default collapsed
                collapsibleSection(title: lang.t("profile.schedule"), icon: "clock", expanded: $expandedSchedule) {
                    NavigationLink {
                        ScheduleSettingsView()
                    } label: {
                        HStack {
                            Label("Horario laboral", systemImage: "clock")
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
                        Label("Vacaciones y ausencias", systemImage: "sun.max")
                    }
                }

                // 7. Notificaciones — collapsible, default collapsed
                collapsibleSection(title: lang.t("profile.notifications"), icon: "bell.fill", expanded: $expandedNotifications) {
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

                // 8. Logout — always visible
                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                        dismiss()
                    } label: {
                        Label(lang.t("profile.logout"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle(lang.t("profile.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.t("action.close")) { dismiss() }
                }
            }
            .task {
                await pushManager.refreshPermissionStatus()
                loadAssistantSettings()
                await loadGoogleAccounts()
                await loadCurrentMode()
            }
        }
    }

    // MARK: - Collapsible Section Builder

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        icon: String,
        expanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section {
            if expanded.wrappedValue {
                content()
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.ctrlPurple)
                        .frame(width: 20)
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        UserDefaults.standard.set(selectedLanguage, forKey: "appLanguage")

        let body = UpdateUserBody(
            assistantName: finalName,
            assistantPersonality: assistantPersonality,
            assistantVoice: assistantVoice,
            language: selectedLanguage
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
        let sampleText = AssistantViewModel.voicePreviewText(for: vc.langGroup)
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
            callbackURLScheme: "ctrl"
        ) { _, _ in
            // Backend redirects to ctrl://oauth/google/success after linking.
            // ASWebAuthenticationSession auto-dismisses on scheme match.
            Task { await loadGoogleAccounts() }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = oauthCoordinator
        session.start()
    }

    private func loadGoogleAccounts() async {
        gcalLoading = true
        do {
            let accounts: [GoogleCalendarAccount] = try await APIClient.shared.request(.googleCalendarAccounts)
            googleAccounts = accounts
            print("[ProfileView] Loaded \(accounts.count) Google account(s)")
        } catch {
            print("[ProfileView] Failed to load Google accounts: \(error)")
            googleAccounts = []
        }
        gcalLoading = false
    }

    private func toggleAccountActive(_ account: GoogleCalendarAccount) async {
        let body = UpdateGoogleCalendarBody(isActive: !account.isActive)
        do {
            let _: GoogleCalendarAccount = try await APIClient.shared.request(
                .googleCalendarAccount(id: account.id),
                method: "PATCH",
                body: body
            )
            await loadGoogleAccounts()
        } catch { }
    }

    private func deleteAccount(_ account: GoogleCalendarAccount) async {
        do {
            try await APIClient.shared.requestVoid(
                .googleCalendarAccount(id: account.id),
                method: "DELETE"
            )
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
