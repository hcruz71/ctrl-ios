import Foundation

struct Project: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String?
    var status: String
    var priorityLevel: String
    var startDate: String?
    var endDate: String?
    var color: String
    var icon: String
    var progress: Int
    var objectiveId: UUID?
    var objective: Objective?
    var taskCount: Int?
    var completedTaskCount: Int?
    var meetingCount: Int?
    var delegationCount: Int?
    var isDeleted: Bool?
    var deletedAt: Date?

    let createdAt: Date?
    let updatedAt: Date?

    var taskProgress: Int {
        guard let total = taskCount, total > 0, let completed = completedTaskCount else {
            return progress
        }
        return Int(Double(completed) / Double(total) * 100)
    }
}

struct CreateProjectBody: Encodable {
    var name: String
    var description: String?
    var objectiveId: String?
    var status: String?
    var priorityLevel: String?
    var startDate: String?
    var endDate: String?
    var color: String?
    var icon: String?
}

struct UpdateProjectBody: Encodable {
    var name: String?
    var description: String?
    var objectiveId: String?
    var status: String?
    var priorityLevel: String?
    var startDate: String?
    var endDate: String?
    var color: String?
    var icon: String?
    var progress: Int?
}

struct ProjectSummary: Codable {
    var project: Project
    var tasks: ProjectTaskSummary
    var meetings: ProjectMeetingSummary
    var delegations: ProjectDelegationSummary
}

struct ProjectTaskSummary: Codable {
    var total: Int
    var completed: Int
    var progress: Int
    var byPriority: [String: Int]?
}

struct ProjectMeetingSummary: Codable {
    var total: Int
}

struct ProjectDelegationSummary: Codable {
    var total: Int
    var active: Int
}
