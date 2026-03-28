import Foundation

struct EmailSummary: Codable, Identifiable {
    let id: String
    var threadId: String?
    var from: String
    var to: String?
    var subject: String
    var snippet: String?
    var date: String?
    var labels: [String]?
    var isUnread: Bool?

    var senderName: String {
        // Extract name from "Name <email>" format
        if let range = from.range(of: "<") {
            return String(from[from.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return from
    }
}

struct EmailAnalysisResult: Codable {
    var totalEmails: Int
    var period: String?
    var emails: [EmailSummary]?
    var analysis: String
    var categories: EmailCategories?
    var suggestedTasks: [SuggestedEmailTask]?
}

struct EmailCategories: Codable {
    var urgente: [EmailSummary]?
    var requiereAccion: [EmailSummary]?
    var informativo: [EmailSummary]?
    var ignorar: [EmailSummary]?
}

struct SuggestedEmailTask: Codable, Identifiable {
    var id: String { title }
    var title: String
    var fromEmail: String?
    var priority: String?
    var dueDate: String?
}

struct GmailImportResult: Codable {
    var imported: Int
    var skipped: Int
    var total: Int
}

struct GmailImportBody: Encodable {
    var hours: Int
    var unreadOnly: Bool?
    var excludeNewsletters: Bool?
}
