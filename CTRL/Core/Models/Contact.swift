import Foundation

struct Contact: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
    var networkType: String?
    var networkNotes: String?
    var influenceLevel: String?
    var relationshipStrength: Int?
    let createdAt: Date?
    let updatedAt: Date?

    var networkLabel: String {
        switch networkType {
        case "operativa":    return "Operativa"
        case "personal":     return "Personal"
        case "estrategica":  return "Estrategica"
        default:             return "Sin clasificar"
        }
    }

    var networkIcon: String {
        switch networkType {
        case "operativa":    return "wrench.and.screwdriver"
        case "personal":     return "leaf"
        case "estrategica":  return "target"
        default:             return "questionmark.circle"
        }
    }
}

struct CreateContactBody: Encodable {
    var name: String
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
    var networkType: String?
    var networkNotes: String?
    var influenceLevel: String?
    var relationshipStrength: Int?
}

struct UpdateContactBody: Encodable {
    var name: String?
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
    var networkType: String?
    var networkNotes: String?
    var influenceLevel: String?
    var relationshipStrength: Int?
}

struct MeetingProductivity: Codable {
    var totalThisWeek: Int
    var withObjective: Int
    var withoutObjective: Int
    var objectiveCoveragePct: Int
    var byObjective: [ObjectiveMeetingCount]
    var topContacts: [ContactMeetingCount]
    var avgMeetingsPerDay: Double
    var busiestDay: String
}

struct ObjectiveMeetingCount: Codable {
    var objectiveTitle: String
    var meetingCount: Int
}

struct ContactMeetingCount: Codable {
    var name: String
    var meetingCount: Int
}
