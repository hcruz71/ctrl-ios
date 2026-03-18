import Foundation

struct Meeting: Codable, Identifiable {
    let id: UUID
    var title: String
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateMeetingBody: Encodable {
    var title: String
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
}

struct UpdateMeetingBody: Encodable {
    var title: String?
    var meetingDate: String?
    var meetingTime: String?
    var participants: String?
    var agenda: String?
    var actionItems: String?
}
