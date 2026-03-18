import Foundation

/// Named `CTRLTask` to avoid collision with Swift's concurrency `Task`.
struct CTRLTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var priority: String
    var project: String?
    var dueDate: String?
    var done: Bool
    var contacts: [Contact]?
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateTaskBody: Encodable {
    var title: String
    var priority: String = "media"
    var project: String?
    var dueDate: String?
    var done: Bool = false
    var contactIds: [String]?
}

struct UpdateTaskBody: Encodable {
    var title: String?
    var priority: String?
    var project: String?
    var dueDate: String?
    var done: Bool?
    var contactIds: [String]?
}
