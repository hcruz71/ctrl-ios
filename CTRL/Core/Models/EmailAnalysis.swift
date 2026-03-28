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

struct SkippedBreakdown: Codable {
    var duplicate: Int?
    var newsletter: Int?
    var noBody: Int?
    var read: Int?
}

struct GmailImportResult: Codable {
    var imported: Int
    var skipped: Int
    var skippedBreakdown: SkippedBreakdown?
    var totalFound: Int?
}

struct GmailImportBody: Encodable {
    var hours: Int
    var maxResults: Int?
    var unreadOnly: Bool?
    var excludeNewsletters: Bool?
    var forceReimport: Bool?
}

struct ImportedEmailsCount: Codable {
    var count: Int
}

struct ImportedEmailItem: Codable, Identifiable {
    let id: String
    var gmailId: String?
    var subject: String?
    var sender: String?
    var senderEmail: String?
    var receivedAt: String?
    var snippet: String?
    var aiCategory: String?
    var isRead: Bool?
    var hasAttachments: Bool?
    var threadId: String?
    var importance: String?
    // Full detail fields
    var bodyText: String?
    var bodyHtml: String?
    var recipients: [String]?
    var ccRecipients: [String]?
    var labels: [String]?
}

struct ImportedEmailsPage: Codable {
    var emails: [ImportedEmailItem]
    var total: Int
    var limit: Int
    var offset: Int
}
