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
    var googleCalendarId: UUID?
    var objectiveId: UUID?
    var minutesProcessedAt: Date?
    var objective: Objective?
    let createdAt: Date?
    let updatedAt: Date?

    var icsImported: Bool?

    // Attendance & scoring
    var organizer: String?
    var attendees: [MeetingAttendee]?
    var attendanceStatus: String?
    var importanceScore: Int?
    var importanceReason: String?
    var delegateContactId: UUID?
    var delegateBriefing: String?
    var delegateEmailSentAt: Date?

    var isFromGoogle: Bool { googleCalendarEventId != nil }

    var importanceLevel: String {
        guard let score = importanceScore else { return "sin evaluar" }
        if score >= 70 { return "alta" }
        if score >= 30 { return "media" }
        return "baja"
    }

    var attendeeCount: Int {
        attendees?.count ?? 0
    }
}

struct MeetingAttendee: Codable {
    var name: String?
    var email: String?
    var isOrganizer: Bool?
    var contactId: String?
    var status: String?
}

struct ICSImportEventBody: Encodable {
    var title: String
    var date: String
    var time: String?
    var participants: String?
    var agenda: String?
    var organizer: String?
    var attendees: [ICSAttendee]?
}

struct ICSImportBody: Encodable {
    var events: [ICSImportEventBody]
}

struct ICSImportResult: Codable {
    var imported: Int
    var skipped: Int
    var updated: Int?
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
