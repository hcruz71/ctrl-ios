import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let role: String?
    let plan: String?
    var assistantName: String?
    var assistantPersonality: String?
    var assistantVoice: String?
    var language: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct UpdateUserBody: Encodable {
    var name: String?
    var assistantName: String?
    var assistantPersonality: String?
    var assistantVoice: String?
    var language: String?
}

struct UsageSummary: Codable {
    let plan: String
    let interactionsUsed: Int
    let interactionsLimit: Int
    let interactionsRemaining: Int
    let tokensInputTotal: Int
    let tokensOutputTotal: Int
    let costUsdTotal: Double
    let resetDate: String
    let percentageUsed: Int
}
