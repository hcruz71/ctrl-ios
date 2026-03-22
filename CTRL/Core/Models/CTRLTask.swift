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
    var startDate: String?
    var durationDays: Int?
    var done: Bool
    var inbox: Bool?
    var capturedAt: Date?
    var contacts: [Contact]?

    var duration: String? {
        guard let days = durationDays else { return nil }
        if days == 1 { return "1 dia" }
        if days < 7 { return "\(days) dias" }
        if days < 30 { return "\(days / 7) semanas" }
        return "\(days / 30) meses"
    }

    // Delegation fields
    var isDelegated: Bool?
    var assignee: String?
    var assigneeContactId: UUID?
    var delegationStatus: String?
    var delegationNotes: String?
    var emailSentAt: Date?

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
    var startDate: String?
    var done: Bool = false
    var inbox: Bool?
    var contactIds: [String]?
    var isDelegated: Bool?
    var assignee: String?
    var assigneeContactId: String?
    var delegationNotes: String?
}

struct UpdateTaskBody: Encodable {
    var title: String?
    var priorityLevel: String?
    var priorityOrder: Int?
    var project: String?
    var projectId: String?
    var dueDate: String?
    var startDate: String?
    var done: Bool?
    var inbox: Bool?
    var contactIds: [String]?
    var isDelegated: Bool?
    var assignee: String?
    var assigneeContactId: String?
    var delegationStatus: String?
    var delegationNotes: String?
}

struct ReorderTasksBody: Encodable {
    var priorityLevel: String
    var orderedIds: [String]
}
