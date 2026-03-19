import Foundation
import Speech
import AVFoundation
import os.log

private let logger = Logger(subsystem: "com.hector.ctrl", category: "AssistantVM")

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

@MainActor
final class AssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isRecording = false
    @Published var errorMessage: String?

    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    init() {
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hola, soy tu asistente CTRL. Puedo ayudarte a crear tareas, reuniones, ver tu resumen del día y más. ¿En qué te ayudo?"
        ))
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
        defer { isLoading = false }

        // Build conversation history for the API
        let apiMessages: [[String: String]] = messages
            .filter { $0.role == .user || $0.role == .assistant }
            .map { msg in
                [
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content,
                ]
            }

        let body: [String: Any] = ["messages": apiMessages]

        do {
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
        } catch {
            logger.error("Assistant error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(
                role: .assistant,
                content: "Hubo un error al procesar tu mensaje. Intenta de nuevo."
            ))
        }
    }

    private func toolDescription(_ dict: [String: Any]) -> String {
        let tool = dict["tool"] as? String ?? ""
        let input = dict["input"] as? [String: Any] ?? [:]

        switch tool {
        case "create_task":
            return "Tarea creada: \(input["title"] ?? "")"
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

    // MARK: - Speech recognition

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Reconocimiento de voz no disponible"
            return
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard status == .authorized else {
                    self?.errorMessage = "Permiso de voz denegado"
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
        } catch {
            errorMessage = "Error al iniciar grabación"
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.inputText = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }
}
