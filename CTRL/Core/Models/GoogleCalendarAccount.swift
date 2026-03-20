import Foundation

struct GoogleCalendarAccount: Codable, Identifiable {
    let id: UUID
    let email: String
    var label: String?
    var isActive: Bool
    var lastSyncAt: Date?
    let createdAt: Date?
}

struct UpdateGoogleCalendarBody: Encodable {
    var label: String?
    var isActive: Bool?
}
