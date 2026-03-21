import Foundation
import WatchConnectivity

/// iPhone-side bridge that receives Watch messages and proxies to the backend.
/// Manages its own WCSession — no dependency on the Watch-only WatchConnectivityManager.
final class WatchBridge: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchBridge()

    private override init() {
        super.init()
    }

    func setup() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            await self.handle(message: message, reply: replyHandler)
        }
    }

    // MARK: - Message Handler

    @MainActor
    private func handle(message: [String: Any], reply: @escaping ([String: Any]) -> Void) async {
        let type = message["type"] as? String ?? ""

        switch type {
        case "voice_query":
            await handleVoiceQuery(message, reply: reply)
        case "complete_task":
            await handleCompleteTask(message, reply: reply)
        case "fetch_tasks":
            await handleFetchTasks(reply: reply)
        case "fetch_meetings":
            await handleFetchMeetings(reply: reply)
        default:
            reply(["type": "error", "text": "Unknown command"])
        }
    }

    // MARK: - Voice Query

    @MainActor
    private func handleVoiceQuery(_ message: [String: Any], reply: @escaping ([String: Any]) -> Void) async {
        guard let text = message["text"] as? String else {
            reply(["type": "assistant_response", "text": "No se recibio texto"])
            return
        }

        do {
            struct ChatBody: Encodable {
                let messages: [ChatMsg]
            }
            struct ChatMsg: Encodable {
                let role: String
                let content: String
            }
            struct ChatResult: Decodable {
                let response: String
            }

            let body = ChatBody(messages: [ChatMsg(role: "user", content: text)])
            let result: ChatResult = try await APIClient.shared.request(.assistantChat, body: body)
            reply(["type": "assistant_response", "text": result.response, "speak": true])
        } catch {
            reply(["type": "assistant_response", "text": "Error al procesar"])
        }
    }

    // MARK: - Complete Task

    @MainActor
    private func handleCompleteTask(_ message: [String: Any], reply: @escaping ([String: Any]) -> Void) async {
        guard let taskId = message["taskId"] as? String,
              let uuid = UUID(uuidString: taskId) else {
            reply(["type": "error"])
            return
        }

        do {
            struct UpdateBody: Encodable { let done: Bool }
            let _: EmptyData = try await APIClient.shared.request(
                .task(id: uuid), body: UpdateBody(done: true)
            )
            reply(["type": "task_completed", "taskId": taskId])
        } catch {
            reply(["type": "error"])
        }
    }

    // MARK: - Fetch Tasks

    @MainActor
    private func handleFetchTasks(reply: @escaping ([String: Any]) -> Void) async {
        do {
            let tasks: [CTRLTask] = try await APIClient.shared.request(.tasksToday)
            let watchTasks = tasks
                .filter { $0.priorityLevel == "A" && !$0.done }
                .prefix(10)
                .map { WatchTaskDTO(id: $0.id.uuidString, title: $0.title, priorityLevel: $0.priorityLevel, priorityOrder: $0.priorityOrder, done: $0.done) }
            let data = try JSONEncoder().encode(Array(watchTasks))
            reply(["type": "tasks_update", "tasks": data])
        } catch {
            reply(["type": "tasks_update", "tasks": Data()])
        }
    }

    // MARK: - Fetch Meetings

    @MainActor
    private func handleFetchMeetings(reply: @escaping ([String: Any]) -> Void) async {
        do {
            let meetings: [Meeting] = try await APIClient.shared.request(.meetingsToday)
            let watchMeetings = meetings.map {
                WatchMeetingDTO(id: $0.id.uuidString, title: $0.title, meetingTime: $0.meetingTime, meetingDate: $0.meetingDate)
            }
            let data = try JSONEncoder().encode(watchMeetings)
            reply(["type": "meetings_update", "meetings": data])
        } catch {
            reply(["type": "meetings_update", "meetings": Data()])
        }
    }
}

// MARK: - DTOs for Watch serialization

private struct WatchTaskDTO: Encodable {
    let id: String
    let title: String
    let priorityLevel: String?
    let priorityOrder: Int?
    let done: Bool
}

private struct WatchMeetingDTO: Encodable {
    let id: String
    let title: String
    let meetingTime: String?
    let meetingDate: String?
}
