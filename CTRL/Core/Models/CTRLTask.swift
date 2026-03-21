import Foundation

/// Named `CTRLTask` to avoid collision with Swift's concurrency `Task`.
struct CTRLTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var priorityLevel: String?
    var priorityOrder: Int?
    var project: String?
    var projectId: UUID?
    var dueDate: String?
    var done: Bool
    var inbox: Bool?
    var capturedAt: Date?
    var contacts: [Contact]?
    let createdAt: Date?
    let updatedAt: Date?

    /// Display label e.g. "A1", "B3", nil for inbox
    var priorityLabel: String? {
        guard let level = priorityLevel, let order = priorityOrder else { return nil }
        return "\(level)\(order)"
    }
}

struct CreateTaskBody: Encodable {
    var title: String
    var priorityLevel: String?
    var priorityOrder: Int?
    var project: String?
    var projectId: String?
    var dueDate: String?
    var done: Bool = false
    var inbox: Bool?
    var contactIds: [String]?
}

struct UpdateTaskBody: Encodable {
    var title: String?
    var priorityLevel: String?
    var priorityOrder: Int?
    var project: String?
    var projectId: String?
    var dueDate: String?
    var done: Bool?
    var inbox: Bool?
    var contactIds: [String]?
}

struct ReorderTasksBody: Encodable {
    var priorityLevel: String
    var orderedIds: [String]
}
