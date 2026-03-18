import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let role: String?
    let createdAt: Date?
    let updatedAt: Date?
}
