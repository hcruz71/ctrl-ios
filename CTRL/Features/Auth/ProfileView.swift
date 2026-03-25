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
    @Environment(\.dismiss) private var dismiss

    @State private var assistantName: String = ""
    @State private var assistantPersonality: String = "ejecutivo"
    @State private var assistantVoice: String = "es-MX-female"
    @State private var isSaving = false
    @State private var previewSynthesizer = AVSpeechSynthesizer()

    // MARK: Collapsible section state
    @AppStorage("profile.section.assistant") private var expandedAssistant = false
    @AppStorage("profile.section.voice") private var expandedVoice = false
    @AppStorage("profile.section.language") private var expandedLanguage = false
    @AppStorage("profile.section.byok") private var expandedByok = false
    @State private var selectedLanguage: String = LanguageManager.shared.currentLanguage
    @State private var showLanguageRestart = false
    @State private var byokEnabled = KeychainHelper.getAnthropicKey()?.isEmpty == false
    @State private var byokKeyInput = ""
    @State private var byokStatus: ByokStatus = .none
    @State private var showResetOnboardingAlert = false

    private enum ByokStatus {
        case none, validating, valid, invalid(String)
    }

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
                        HStack {
                            Label("Plan", systemImage: "crown")
                            Spacer()
                            NavigationLink {
                                SubscriptionView()
                            } label: {
                                Text(currentPlanEnum.label.uppercased())
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(planBadgeColor.opacity(0.15))
                                    .foregroundStyle(planBadgeColor)
                                    .clipShape(Capsule())
                            }
                        }
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

                // 3. Idioma
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

                // 4. Voz del Asistente
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

                // 4.5 API Key propia (BYOK)
                collapsibleSection(title: lang.t("profile.byok"), icon: "key.fill", expanded: $expandedByok) {
                    Toggle("Usar mi propia API Key", isOn: $byokEnabled)
                        .onChange(of: byokEnabled) { enabled in
                            if !enabled {
                                KeychainHelper.deleteAnthropicKey()
                                byokKeyInput = ""
                                byokStatus = .none
                            }
                        }

                    if byokEnabled {
                        SecureField("sk-ant-...", text: $byokKeyInput)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.system(.body, design: .monospaced))
                            .onAppear {
                                byokKeyInput = KeychainHelper.getAnthropicKey() ?? ""
                            }

                        HStack {
                            Button {
                                validateAndSaveByokKey()
                            } label: {
                                HStack(spacing: 4) {
                                    if case .validating = byokStatus {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                    Text("Verificar key")
                                }
                            }
                            .disabled(byokKeyInput.isEmpty || {
                                if case .validating = byokStatus { return true }
                                return false
                            }())

                            Spacer()

                            switch byokStatus {
                            case .valid:
                                Label("Key valida — uso ilimitado", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            case .invalid(let msg):
                                Label(msg, systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }

                // 5. Guide & Settings
                Section {
                    Button {
                        showResetOnboardingAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .foregroundColor(.ctrlPurple)
                            Text(lang.t("profile.restart_onboarding"))
                                .foregroundColor(.ctrlPurple)
                        }
                    }
                } header: {
                    Text(lang.t("profile.help_section"))
                }

                // 6. Logout — always visible
                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                        dismiss()
                    } label: {
                        Label(lang.t("profile.logout"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .alert(
                lang.t("profile.restart_onboarding"),
                isPresented: $showResetOnboardingAlert
            ) {
                Button(lang.t("action.confirm")) {
                    Task {
                        await authManager.resetOnboarding()
                        dismiss()
                    }
                }
                Button(lang.t("action.cancel"), role: .cancel) { }
            } message: {
                Text(lang.t("profile.restart_onboarding_msg"))
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
            .navigationTitle(lang.t("profile.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.t("action.close")) { dismiss() }
                }
            }
            .task {
                await authManager.fetchProfile()
                loadAssistantSettings()
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

    private var currentPlanEnum: SubscriptionPlan {
        guard let planStr = authManager.currentUser?.plan else { return .free }
        return SubscriptionPlan(rawValue: planStr) ?? .free
    }

    private var planBadgeColor: Color {
        switch currentPlanEnum {
        case .free: return .gray
        case .pro: return Color.ctrlPurple
        case .team: return .orange
        }
    }

    private func validateAndSaveByokKey() {
        let key = byokKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        byokStatus = .validating
        Task {
            do {
                // Quick validation: try a minimal API call
                let url = URL(string: "https://api.anthropic.com/v1/messages")!
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue(key, forHTTPHeaderField: "x-api-key")
                req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = """
                {"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}
                """
                req.httpBody = body.data(using: .utf8)

                let (_, response) = try await URLSession.shared.data(for: req)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0

                if (200...299).contains(status) {
                    KeychainHelper.saveAnthropicKey(key)
                    byokStatus = .valid
                } else if status == 401 {
                    byokStatus = .invalid("API Key invalida")
                } else {
                    // Non-auth error means key format is OK
                    KeychainHelper.saveAnthropicKey(key)
                    byokStatus = .valid
                }
            } catch {
                byokStatus = .invalid("Error de conexion")
            }
        }
    }

}
