import Foundation

struct Contact: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateContactBody: Encodable {
    var name: String
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
}

struct UpdateContactBody: Encodable {
    var name: String?
    var email: String?
    var phone: String?
    var company: String?
    var role: String?
}
