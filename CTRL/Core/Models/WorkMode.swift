import Foundation

enum WorkMode: String, Codable {
    case work
    case personal
    case rest
    case vacation

    var label: String {
        switch self {
        case .work:     return "Trabajo"
        case .personal: return "Personal"
        case .rest:     return "Descanso"
        case .vacation: return "Vacaciones"
        }
    }

    var icon: String {
        switch self {
        case .work:     return "briefcase.fill"
        case .personal: return "house.fill"
        case .rest:     return "moon.fill"
        case .vacation: return "sun.max.fill"
        }
    }

    var color: String {
        switch self {
        case .work:     return "blue"
        case .personal: return "green"
        case .rest:     return "gray"
        case .vacation: return "orange"
        }
    }
}

struct WorkModeResponse: Codable {
    let mode: WorkMode
    let message: String?
}

struct UserSchedule: Codable, Identifiable {
    let id: UUID?
    var workDays: [Int]
    var workStart: String
    var workEnd: String
    var personalStart: String
    var personalEnd: String
    var timezone: String
    var restMessage: String
}

struct UserAbsence: Codable, Identifiable {
    let id: UUID
    var startDate: String
    var endDate: String
    var type: String
    var substituteContactId: UUID?
    var substituteName: String?
    var substituteEmail: String?
    var substitutePhone: String?
    var notes: String?
    var handoverDocument: String?
    var stakeholderMessage: String?
    var returnPlan: String?
    var documentsGeneratedAt: Date?
    var isActive: Bool
    let createdAt: Date?
}

struct CreateAbsenceBody: Encodable {
    var startDate: String
    var endDate: String
    var type: String
    var substituteContactId: String?
    var substituteName: String?
    var substituteEmail: String?
    var substitutePhone: String?
    var notes: String?
}
