import Foundation

struct Objective: Codable, Identifiable {
    let id: UUID
    var title: String
    var keyResult: String?
    var area: String
    var horizon: String
    var progress: Int
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateObjectiveBody: Encodable {
    var title: String
    var keyResult: String?
    var area: String = "Personal"
    var horizon: String = "mes"
    var progress: Int = 0
}

struct UpdateObjectiveBody: Encodable {
    var title: String?
    var keyResult: String?
    var area: String?
    var horizon: String?
    var progress: Int?
}
