import Foundation
import Speech
import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.hector.ctrl", category: "AssistantVM")

// MARK: - Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    var actions: [AssistantAction]?

    enum Role {
        case user
        case assistant
    }
}

struct AssistantAction: Identifiable {
    let id = UUID()
    let tool: String
    let description: String
    let success: Bool
}

// MARK: - Voice State

enum VoiceState {
    case idle
    case listening
    case processing
    case speaking
    case paused
}

// MARK: - Mic Mode

enum MicMode: String {
    case pushToTalk = "pushToTalk"
    case continuousListening = "continuousListening"
}

// MARK: - TTS Delegate

private class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Cancelled by interrupt — handled by handleButtonPress
    }
}

// MARK: - ViewModel

@MainActor
final class AssistantViewModel: ObservableObject {
    // MARK: Published state
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var liveTranscript = ""
    @Published var errorMessage: String?
    @Published var micMode: MicMode = .pushToTalk
    @Published var isWaitingToSend = false
    @Published var isPaused = false

    private var hasStartedSession = false
    private var releaseDelayTask: Task<Void, Never>?

    var voiceState: VoiceState {
        if isPaused { return .paused }
        if isSpeaking { return .speaking }
        if isLoading { return .processing }
        if isRecording { return .listening }
        return .idle
    }

    // MARK: Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: AssistantViewModel.speechLocale))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    // MARK: Text-to-speech
    private let synthesizer = AVSpeechSynthesizer()
    private let ttsDelegate = TTSDelegate()

    // MARK: Silence detection
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5

    // MARK: Init

    init() {
        let savedMode = UserDefaults.standard.string(forKey: "assistantMode") ?? ""
        micMode = MicMode(rawValue: savedMode) ?? .pushToTalk

        let name = UserDefaults.standard.string(forKey: "assistantName") ?? "CTRL"
        let greeting = Self.buildGreeting(name: name)
        messages.append(ChatMessage(
            role: .assistant,
            content: greeting
        ))

        synthesizer.delegate = ttsDelegate
        ttsDelegate.onFinish = { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSpeaking = false
                // Auto-restart mic after TTS in continuous mode (with cooldown)
                guard let self,
                      self.micMode == .continuousListening,
                      !self.isPaused else { return }
                // 0.5s cooldown to avoid capturing TTS echo
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !self.isPaused, !self.isRecording, !self.isLoading else { return }
                self.startRecording()
            }
        }
    }

    // MARK: - Session Start

    func startSession() {
        guard !hasStartedSession else { return }
        hasStartedSession = true

        if let greeting = messages.first?.content {
            speak(greeting)
        }
    }

    // MARK: - Mic Mode Toggle

    func toggleMicMode() {
        isPaused = false
        if micMode == .pushToTalk {
            micMode = .continuousListening
            UserDefaults.standard.set(micMode.rawValue, forKey: "assistantMode")
            if !isRecording && !isLoading && !isSpeaking {
                startRecording()
            }
        } else {
            micMode = .pushToTalk
            UserDefaults.standard.set(micMode.rawValue, forKey: "assistantMode")
            if isRecording {
                stopRecording()
                liveTranscript = ""
            }
        }
    }

    // MARK: - Response Cleaning

    /// Strips emojis, markdown formatting, and excessive whitespace from assistant responses.
    func cleanResponse(_ text: String) -> String {
        var result = text

        // Remove markdown bold/italic: ***, **, *
        result = result.replacingOccurrences(
            of: #"\*{1,3}([^*]+)\*{1,3}"#,
            with: "$1",
            options: .regularExpression
        )

        // Remove markdown headers: # ## ### etc.
        result = result.replacingOccurrences(
            of: #"(?m)^#{1,6}\s*"#,
            with: "",
            options: .regularExpression
        )

        // Remove bullet-style dashes at line start: - item
        result = result.replacingOccurrences(
            of: #"(?m)^[\-\•\▪\▸\►]\s*"#,
            with: "",
            options: .regularExpression
        )

        // Remove numbered list prefixes: 1. 2. etc.
        result = result.replacingOccurrences(
            of: #"(?m)^\d+\.\s+"#,
            with: "",
            options: .regularExpression
        )

        // Remove inline code backticks
        result = result.replacingOccurrences(of: "`", with: "")

        // Remove emojis (Unicode emoji ranges)
        result = result.unicodeScalars.filter { scalar in
            let v = scalar.value
            // Basic Latin + common scripts, exclude emoji blocks
            if v <= 0x00FF { return true }                       // Latin
            if (0x0100...0x024F).contains(v) { return true }     // Latin Extended
            if (0x0250...0x02AF).contains(v) { return true }     // IPA
            if (0x0300...0x036F).contains(v) { return true }     // Combining diacriticals
            if (0x2000...0x200F).contains(v) { return true }     // General punctuation (spaces)
            if (0x2010...0x2027).contains(v) { return true }     // Hyphens, dashes, quotes
            if (0x2030...0x205E).contains(v) { return true }     // Per mille, primes, etc.
            if (0x00C0...0x00FF).contains(v) { return true }     // Latin-1 supplement (ñ, á, etc.)
            // Block common emoji ranges
            if (0x1F600...0x1F64F).contains(v) { return false }  // Emoticons
            if (0x1F300...0x1F5FF).contains(v) { return false }  // Misc symbols & pictographs
            if (0x1F680...0x1F6FF).contains(v) { return false }  // Transport & map
            if (0x1F900...0x1F9FF).contains(v) { return false }  // Supplemental symbols
            if (0x1FA00...0x1FA6F).contains(v) { return false }  // Chess, extended-A
            if (0x1FA70...0x1FAFF).contains(v) { return false }  // Extended-A continued
            if (0x2600...0x26FF).contains(v) { return false }    // Misc symbols
            if (0x2700...0x27BF).contains(v) { return false }    // Dingbats
            if (0xFE00...0xFE0F).contains(v) { return false }   // Variation selectors
            if (0x200D == v) { return false }                    // Zero-width joiner
            if (0xE0020...0xE007F).contains(v) { return false }  // Tags
            // Allow everything else (standard text)
            return true
        }.map { Character($0) }.reduce("") { $0 + String($1) }

        // Collapse multiple blank lines into one
        result = result.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Push-to-Talk

    func handleButtonPress() {
        // Cancel pending release delay — user wants to keep talking (push-to-talk)
        if isWaitingToSend {
            releaseDelayTask?.cancel()
            releaseDelayTask = nil
            isWaitingToSend = false
            return
        }

        // Continuous mode: pause/resume logic
        if micMode == .continuousListening {
            // Resume from pause
            if isPaused {
                isPaused = false
                startRecording()
                return
            }

            // Pause TTS
            if isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
                isSpeaking = false
                isPaused = true
                return
            }

            // Pause recording
            if isRecording {
                silenceTimer?.invalidate()
                silenceTimer = nil
                stopRecording()
                liveTranscript = ""
                isPaused = true
                return
            }

            // Idle → start recording
            if !isLoading {
                startRecording()
            }
            return
        }

        // Push-to-talk: interrupt TTS → start listening
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            startRecording()
            return
        }

        // Ignore if already recording or processing
        guard !isRecording, !isLoading else { return }

        startRecording()
    }

    func handleButtonRelease() {
        // Continuous mode: mic stays on after release
        if micMode == .continuousListening { return }

        // Push-to-talk: delay 2s before sending (mic stays on)
        guard isRecording else { return }
        silenceTimer?.invalidate()
        silenceTimer = nil

        isWaitingToSend = true

        releaseDelayTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }

            isWaitingToSend = false
            let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            stopRecording()

            if !text.isEmpty {
                inputText = text
                liveTranscript = ""
                sendMessage()
            }
        }
    }

    // MARK: - Send message

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))

        Task { await callAssistant() }
    }

    private func callAssistant() async {
        isLoading = true
        errorMessage = nil

        var responseToSpeak: String?

        do {
            let apiMessages: [[String: String]] = messages
                .filter { $0.role == .user || $0.role == .assistant }
                .map { msg in
                    [
                        "role": msg.role == .user ? "user" : "assistant",
                        "content": msg.content,
                    ]
                }

            let body: [String: Any] = ["messages": apiMessages]

            guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

            guard let url = URL(string: "\(APIEndpoint.baseURL)/assistant/chat") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let token = AuthManager.shared.token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            request.httpBody = bodyData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                let http = response as? HTTPURLResponse
                throw APIError.server(
                    statusCode: http?.statusCode ?? 500,
                    message: "Error del servidor"
                )
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let chatData = json?["data"] as? [String: Any]
            let rawResponse = chatData?["response"] as? String ?? "Sin respuesta."
            let responseText = cleanResponse(rawResponse)
            let actionsArray = chatData?["actions"] as? [[String: Any]] ?? []

            let actions = actionsArray.map { dict in
                AssistantAction(
                    tool: dict["tool"] as? String ?? "",
                    description: toolDescription(dict),
                    success: dict["success"] as? Bool ?? false
                )
            }

            messages.append(ChatMessage(
                role: .assistant,
                content: responseText,
                actions: actions.isEmpty ? nil : actions
            ))

            responseToSpeak = responseText
        } catch {
            logger.error("Assistant error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription

            let errorText = "Hubo un error al procesar tu mensaje. Intenta de nuevo."
            messages.append(ChatMessage(role: .assistant, content: errorText))

            responseToSpeak = errorText
        }

        isLoading = false

        if let text = responseToSpeak {
            speak(text)
        }
    }

    // MARK: - Text-to-Speech

    private func speak(_ text: String) {
        // Stop mic before TTS to prevent audio loop
        if isRecording {
            stopRecording()
            liveTranscript = ""
        }

        synthesizer.stopSpeaking(at: .immediate)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            logger.error("TTS audio session error: \(error.localizedDescription)")
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.resolveVoice()
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Resolves the user's preferred voice, falling back to es-MX default.
    static func resolveVoice() -> AVSpeechSynthesisVoice? {
        let pref = UserDefaults.standard.string(forKey: "assistantVoice") ?? "es-MX-female"
        let config = voiceConfigs.first { $0.id == pref }
        guard let config else {
            return AVSpeechSynthesisVoice(language: "es-MX")
        }
        // Try exact identifier first
        if let identifier = config.identifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        // Fallback: find by language + name prefix
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        if let match = allVoices.first(where: {
            $0.language == config.language && $0.name.localizedCaseInsensitiveContains(config.namePrefix)
        }) {
            return match
        }
        // Final fallback: any voice for the language
        return AVSpeechSynthesisVoice(language: config.language)
            ?? AVSpeechSynthesisVoice(language: "es-MX")
    }

    // MARK: - Voice catalog

    struct VoiceConfig: Identifiable {
        let id: String          // UserDefaults key
        let flag: String
        let label: String
        let language: String
        let namePrefix: String
        let identifier: String? // com.apple.voice.compact...
        let langGroup: String   // "es", "en", "pt", "fr", "de"
    }

    static let voiceConfigs: [VoiceConfig] = [
        // Español
        VoiceConfig(id: "es-MX-female", flag: "🇲🇽", label: "Paulina (es-MX)",
                    language: "es-MX", namePrefix: "Paulina",
                    identifier: "com.apple.voice.compact.es-MX.Paulina", langGroup: "es"),
        VoiceConfig(id: "es-MX-male", flag: "🇲🇽", label: "Juan (es-MX)",
                    language: "es-MX", namePrefix: "Juan",
                    identifier: "com.apple.voice.compact.es-MX.Juan", langGroup: "es"),
        VoiceConfig(id: "es-ES-female", flag: "🇪🇸", label: "Monica (es-ES)",
                    language: "es-ES", namePrefix: "Monica",
                    identifier: "com.apple.voice.compact.es-ES.Monica", langGroup: "es"),
        VoiceConfig(id: "es-ES-male", flag: "🇪🇸", label: "Jorge (es-ES)",
                    language: "es-ES", namePrefix: "Jorge",
                    identifier: "com.apple.voice.compact.es-ES.Jorge", langGroup: "es"),
        // English
        VoiceConfig(id: "en-US-female", flag: "🇺🇸", label: "Samantha (en-US)",
                    language: "en-US", namePrefix: "Samantha",
                    identifier: "com.apple.voice.compact.en-US.Samantha", langGroup: "en"),
        VoiceConfig(id: "en-US-male", flag: "🇺🇸", label: "Alex (en-US)",
                    language: "en-US", namePrefix: "Alex",
                    identifier: nil, langGroup: "en"),
        VoiceConfig(id: "en-GB-male", flag: "🇬🇧", label: "Daniel (en-GB)",
                    language: "en-GB", namePrefix: "Daniel",
                    identifier: "com.apple.voice.compact.en-GB.Daniel", langGroup: "en"),
        VoiceConfig(id: "en-GB-female", flag: "🇬🇧", label: "Kate (en-GB)",
                    language: "en-GB", namePrefix: "Kate",
                    identifier: nil, langGroup: "en"),
        VoiceConfig(id: "en-AU-female", flag: "🇦🇺", label: "Karen (en-AU)",
                    language: "en-AU", namePrefix: "Karen",
                    identifier: "com.apple.voice.compact.en-AU.Karen", langGroup: "en"),
        // Portugues
        VoiceConfig(id: "pt-BR-female", flag: "🇧🇷", label: "Luciana (pt-BR)",
                    language: "pt-BR", namePrefix: "Luciana",
                    identifier: "com.apple.voice.compact.pt-BR.Luciana", langGroup: "pt"),
        VoiceConfig(id: "pt-BR-male", flag: "🇧🇷", label: "Felipe (pt-BR)",
                    language: "pt-BR", namePrefix: "Felipe",
                    identifier: nil, langGroup: "pt"),
        VoiceConfig(id: "pt-PT-female", flag: "🇵🇹", label: "Joana (pt-PT)",
                    language: "pt-PT", namePrefix: "Joana",
                    identifier: "com.apple.voice.compact.pt-PT.Joana", langGroup: "pt"),
        // Francais
        VoiceConfig(id: "fr-FR-male", flag: "🇫🇷", label: "Thomas (fr-FR)",
                    language: "fr-FR", namePrefix: "Thomas",
                    identifier: "com.apple.voice.compact.fr-FR.Thomas", langGroup: "fr"),
        VoiceConfig(id: "fr-FR-female", flag: "🇫🇷", label: "Amelie (fr-FR)",
                    language: "fr-FR", namePrefix: "Amelie",
                    identifier: "com.apple.voice.compact.fr-FR.Amelie", langGroup: "fr"),
        // Deutsch
        VoiceConfig(id: "de-DE-female", flag: "🇩🇪", label: "Anna (de-DE)",
                    language: "de-DE", namePrefix: "Anna",
                    identifier: "com.apple.voice.compact.de-DE.Anna", langGroup: "de"),
        VoiceConfig(id: "de-DE-male", flag: "🇩🇪", label: "Stefan (de-DE)",
                    language: "de-DE", namePrefix: "Stefan",
                    identifier: nil, langGroup: "de"),
    ]

    static func voicePreviewText(for langGroup: String) -> String {
        switch langGroup {
        case "en": return "Hello, I am your CTRL assistant"
        case "pt": return "Ola, sou seu assistente CTRL"
        case "fr": return "Bonjour, je suis votre assistant CTRL"
        case "de": return "Hallo, ich bin Ihr CTRL-Assistent"
        default:   return "Hola, soy tu asistente CTRL"
        }
    }

    /// Locale identifier for SFSpeechRecognizer based on user's selected language.
    static var speechLocale: String {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
        switch lang {
        case "en": return "en-US"
        case "pt": return "pt-BR"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        default:   return "es-MX"
        }
    }

    // MARK: - Silence Detection

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        guard !isWaitingToSend else { return }
        guard !liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSilenceDetected()
            }
        }
    }

    private func handleSilenceDetected() {
        let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, isRecording, !isLoading else { return }

        // VAD in continuous mode: require 3+ words to filter noise/echo
        if micMode == .continuousListening && text.split(separator: " ").count < 3 {
            liveTranscript = ""
            restartListening()
            return
        }

        inputText = text
        liveTranscript = ""
        stopRecording()
        sendMessage()
    }

    private func restartListening() {
        stopRecording()
        startRecording()
    }

    // MARK: - Tool Descriptions

    private func toolDescription(_ dict: [String: Any]) -> String {
        let tool = dict["tool"] as? String ?? ""
        let input = dict["input"] as? [String: Any] ?? [:]

        switch tool {
        case "create_task":
            let level = input["priority_level"] as? String
            let levelLabel = level.map { " [\($0)]" } ?? " [Inbox]"
            return "Tarea creada\(levelLabel): \(input["title"] ?? "")"
        case "complete_task":
            return "Tarea completada"
        case "create_meeting":
            return "Reunión creada: \(input["title"] ?? "")"
        case "create_delegation":
            return "Delegación creada: \(input["title"] ?? "")"
        case "update_objective_progress":
            return "Objetivo actualizado: \(input["progress"] ?? 0)%"
        case "update_delegation_status":
            return "Delegación actualizada: \(input["status"] ?? "")"
        default:
            return tool.replacingOccurrences(of: "_", with: " ")
        }
    }

    // MARK: - Context-aware greeting

    static func buildGreeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"

        switch lang {
        case "en":
            let greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
            return "\(greeting), I am \(name). How can I help you today?"
        case "pt":
            let greeting = hour < 12 ? "Bom dia" : hour < 18 ? "Boa tarde" : "Boa noite"
            return "\(greeting), sou \(name). Como posso ajuda-lo hoje?"
        case "fr":
            let greeting = hour < 18 ? "Bonjour" : "Bonsoir"
            return "\(greeting), je suis \(name). Comment puis-je vous aider?"
        case "de":
            let greeting = hour < 12 ? "Guten Morgen" : hour < 18 ? "Guten Tag" : "Guten Abend"
            return "\(greeting), ich bin \(name). Wie kann ich Ihnen helfen?"
        default:
            let saludo = hour < 12 ? "Buenos dias" : hour < 18 ? "Buenas tardes" : "Buenas noches"
            let weekday = Calendar.current.component(.weekday, from: Date())
            let contexto: String
            switch (weekday, hour) {
            case (2, 0..<12):
                contexto = "Arrancamos semana. Revisamos tus prioridades?"
            case (6, 15...23):
                contexto = "Cerrando semana. Revisamos que queda pendiente?"
            case (_, 0..<10):
                contexto = "Empezamos con tu briefing del dia?"
            default:
                contexto = "En que nos enfocamos?"
            }
            return "\(saludo), soy \(name). \(contexto)"
        }
    }

    // MARK: - Priority Parsing (Franklin Covey)

    /// Parses natural language to extract Franklin Covey priority level.
    /// Returns "A", "B", "C", or nil (inbox).
    static func parsePriorityLevel(from text: String) -> String? {
        let lower = text.lowercased()

        // Level A: urgente
        let aPatterns = ["prioridad a", "prioridad: a", "urgente", "nivel a", "tipo a"]
        for p in aPatterns {
            if lower.contains(p) { return "A" }
        }

        // Level B: importante
        let bPatterns = ["prioridad b", "prioridad: b", "importante", "nivel b", "tipo b"]
        for p in bPatterns {
            if lower.contains(p) { return "B" }
        }

        // Level C: puede esperar
        let cPatterns = ["prioridad c", "prioridad: c", "puede esperar", "nivel c", "tipo c", "baja prioridad"]
        for p in cPatterns {
            if lower.contains(p) { return "C" }
        }

        return nil
    }

    // MARK: - Speech Recognition

    private func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Reconocimiento de voz no disponible"
            return
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard status == .authorized else {
                    self?.errorMessage = "Permiso de voz denegado. Actívalo en Ajustes."
                    return
                }
                self?.beginAudioSession()
            }
        }
    }

    private func beginAudioSession() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Error al configurar audio"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            liveTranscript = ""
        } catch {
            errorMessage = "Error al iniciar grabación"
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    let newText = result.bestTranscription.formattedString
                    if newText != self.liveTranscript {
                        self.liveTranscript = newText
                        self.resetSilenceTimer()
                    }

                    if result.isFinal {
                        self.silenceTimer?.invalidate()
                        self.handleSilenceDetected()
                        return
                    }
                }

                if error != nil {
                    let transcript = self.liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !transcript.isEmpty {
                        self.silenceTimer?.invalidate()
                        self.handleSilenceDetected()
                    } else {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    private func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }
}
