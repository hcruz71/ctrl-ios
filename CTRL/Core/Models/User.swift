import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let role: String?
    var assistantName: String?
    var assistantPersonality: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct UpdateUserBody: Encodable {
    var name: String?
    var assistantName: String?
    var assistantPersonality: String?
}
