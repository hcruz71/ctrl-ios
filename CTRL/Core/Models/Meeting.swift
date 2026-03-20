import Foundation

struct Meeting: Codable, Identifiable {
    let id: UUID
    var title: String
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
    var googleCalendarEventId: String?
    var googleCalendarSyncAt: Date?
    var objectiveId: UUID?
    var minutesProcessedAt: Date?
    var objective: Objective?
    let createdAt: Date?
    let updatedAt: Date?

    var isFromGoogle: Bool { googleCalendarEventId != nil }
}

struct CreateMeetingBody: Encodable {
    var title: String
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
    var objectiveId: String?
}

struct UpdateMeetingBody: Encodable {
    var title: String?
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
    var objectiveId: String?
}

struct SuggestedTask: Codable, Identifiable {
    var id = UUID()
    var title: String
    var type: String        // "delegate" | "follow_up" | "do_myself"
    var suggestedAssignee: String?
    var suggestedDueDate: String?
    var priorityLevel: String?
    var context: String?
    var contactId: String?
    var included: Bool = true

    enum CodingKeys: String, CodingKey {
        case title, type, suggestedAssignee, suggestedDueDate
        case priorityLevel, context, contactId
    }
}

struct ConfirmTasksBody: Encodable {
    var tasks: [ConfirmTaskItem]
    var meetingId: String?
}

struct ConfirmTaskItem: Encodable {
    var title: String
    var type: String
    var suggestedAssignee: String?
    var suggestedDueDate: String?
    var priorityLevel: String?
    var context: String?
    var contactId: String?
}

struct ConfirmTasksResult: Codable {
    var tasksCreated: Int
    var delegationsCreated: Int
}
