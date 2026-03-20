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

    var voiceState: VoiceState {
        if isSpeaking { return .speaking }
        if isLoading { return .processing }
        if isRecording { return .listening }
        return .idle
    }

    // MARK: Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
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
        let name = UserDefaults.standard.string(forKey: "assistantName") ?? "CTRL"
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hola, soy \(name). ¿En qué te puedo ayudar hoy?"
        ))

        synthesizer.delegate = ttsDelegate
        ttsDelegate.onFinish = { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSpeaking = false
            }
        }
    }

    // MARK: - Push-to-Talk

    func handleButtonPress() {
        // Interrupt TTS → start listening
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
        guard isRecording else { return }
        silenceTimer?.invalidate()
        silenceTimer = nil

        let text = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        stopRecording()

        if !text.isEmpty {
            inputText = text
            liveTranscript = ""
            sendMessage()
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
            let responseText = chatData?["response"] as? String ?? "Sin respuesta."
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
        synthesizer.stopSpeaking(at: .immediate)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
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
    }

    static let voiceConfigs: [VoiceConfig] = [
        VoiceConfig(id: "es-MX-female", flag: "🇲🇽", label: "Paulina (es-MX)",
                    language: "es-MX", namePrefix: "Paulina",
                    identifier: "com.apple.voice.compact.es-MX.Paulina"),
        VoiceConfig(id: "es-MX-male", flag: "🇲🇽", label: "Juan (es-MX)",
                    language: "es-MX", namePrefix: "Juan",
                    identifier: "com.apple.voice.compact.es-MX.Juan"),
        VoiceConfig(id: "es-ES-female", flag: "🇪🇸", label: "Mónica (es-ES)",
                    language: "es-ES", namePrefix: "Mónica",
                    identifier: "com.apple.voice.compact.es-ES.Monica"),
        VoiceConfig(id: "es-ES-male", flag: "🇪🇸", label: "Jorge (es-ES)",
                    language: "es-ES", namePrefix: "Jorge",
                    identifier: "com.apple.voice.compact.es-ES.Jorge"),
        VoiceConfig(id: "en-US-female", flag: "🇺🇸", label: "Nicky (en-US)",
                    language: "en-US", namePrefix: "Nicky",
                    identifier: "com.apple.voice.compact.en-US.Samantha"),
    ]

    // MARK: - Silence Detection

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
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

        inputText = text
        liveTranscript = ""
        stopRecording()
        sendMessage()
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
