import Foundation
import WatchConnectivity
import Combine

#if os(watchOS)
import Speech
#endif

/// Shared connectivity manager for Watch ↔ iPhone communication.
/// On watchOS: sends voice queries, receives responses/data.
/// On iOS: receives queries, proxies to backend, sends results back.
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    #if os(watchOS)
    enum WatchState {
        case idle, listening, processing, responding
    }
    @Published var state: WatchState = .idle
    @Published var lastResponse = ""
    @Published var tasks: [WatchTask] = []
    @Published var meetings: [WatchMeeting] = []

    var nextMeeting: WatchMeeting? {
        meetings.first
    }

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var dictatedText = ""
    #endif

    #if os(iOS)
    /// Callback set by WatchBridge to handle incoming messages
    var onMessageReceived: (([String: Any], @escaping ([String: Any]) -> Void) -> Void)?
    #endif

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - watchOS Methods

    #if os(watchOS)
    func startDictation() {
        state = .listening
        dictatedText = ""

        let locale = Locale(identifier: UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "en-US" : "es-MX")
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async { self?.state = .idle }
                return
            }
            DispatchQueue.main.async { self?.beginRecording() }
        }
    }

    private func beginRecording() {
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine, let recognitionRequest, let speechRecognizer else {
            state = .idle
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result {
                self?.dictatedText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal == true) {
                // handled by stopDictation
            }
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stopDictation() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        let text = dictatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            state = .idle
            return
        }

        state = .processing
        sendVoiceQuery(text)
    }

    func requestTasks() {
        sendMessage(["type": "fetch_tasks"])
    }

    func requestMeetings() {
        sendMessage(["type": "fetch_meetings"])
    }

    func completeTask(id: String) {
        sendMessage(["type": "complete_task", "taskId": id])
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].done = true
        }
    }

    private func sendVoiceQuery(_ text: String) {
        let message: [String: Any] = ["type": "voice_query", "text": text]
        guard WCSession.default.isReachable else {
            lastResponse = "iPhone no disponible"
            state = .idle
            return
        }
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleReply(reply)
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.lastResponse = "Error de conexion"
                self?.state = .idle
            }
        })
    }

    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleReply(reply)
            }
        }, errorHandler: nil)
    }

    private func handleReply(_ reply: [String: Any]) {
        let type = reply["type"] as? String ?? ""

        switch type {
        case "assistant_response":
            lastResponse = reply["text"] as? String ?? ""
            state = .idle

        case "tasks_update":
            if let data = reply["tasks"] as? Data {
                tasks = (try? JSONDecoder().decode([WatchTask].self, from: data)) ?? []
            }

        case "meetings_update":
            if let data = reply["meetings"] as? Data {
                meetings = (try? JSONDecoder().decode([WatchMeeting].self, from: data)) ?? []
            }

        default:
            state = .idle
        }
    }
    #endif
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Session activated
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        onMessageReceived?(message, replyHandler)
    }
    #endif

    #if os(watchOS)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleReply(message)
        }
    }
    #endif
}
