import Foundation

struct WatchTask: Identifiable, Codable {
    let id: String
    let title: String
    let priorityLevel: String?
    let priorityOrder: Int?
    var done: Bool

    var priorityLabel: String? {
        guard let level = priorityLevel, let order = priorityOrder else { return nil }
        return "\(level)\(order)"
    }
}

struct WatchMeeting: Identifiable, Codable {
    let id: String
    let title: String
    let meetingTime: String?
    let meetingDate: String?
}
