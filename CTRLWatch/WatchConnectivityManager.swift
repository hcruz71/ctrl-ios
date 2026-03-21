import Foundation
import WatchConnectivity
import Combine

/// Watch-side connectivity manager.
/// Uses native watchOS dictation (no Speech framework).
/// Sends text to iPhone via WCSession, receives responses.
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    enum WatchState {
        case idle, listening, processing, responding
    }

    @Published var state: WatchState = .idle
    @Published var lastResponse = ""
    @Published var dictatedText = ""
    @Published var tasks: [WatchTask] = []
    @Published var meetings: [WatchMeeting] = []

    var nextMeeting: WatchMeeting? {
        meetings.first
    }

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send dictated text to iPhone

    func sendDictatedText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        state = .processing
        sendVoiceQuery(trimmed)
    }

    // MARK: - Data requests

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

    // MARK: - WCSession messaging

    private func sendVoiceQuery(_ text: String) {
        let message: [String: Any] = ["type": "voice_query", "text": text]
        guard WCSession.default.isReachable else {
            lastResponse = "iPhone no disponible"
            state = .idle
            return
        }
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async { self?.handleReply(reply) }
        }, errorHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastResponse = "Error de conexion"
                self?.state = .idle
            }
        })
    }

    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async { self?.handleReply(reply) }
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
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.handleReply(message) }
    }
}
