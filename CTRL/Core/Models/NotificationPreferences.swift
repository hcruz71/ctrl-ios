import Foundation

struct NotificationPreferences: Codable {
    var id: String?
    var enabled: Bool
    var tasksOverdue: Bool
    var tasksUpcoming: Bool
    var tasksUpcomingHours: Int
    var inboxReminder: Bool
    var inboxReminderHours: Int
    var delegationsOverdue: Bool
    var delegationsOverdueDays: Int
    var morningSummary: Bool
    var morningSummaryTime: String
    var weeklyReview: Bool
    var weeklyReviewTime: String
    var meetingsUpcoming: Bool

    static let defaults = NotificationPreferences(
        enabled: true,
        tasksOverdue: true,
        tasksUpcoming: true,
        tasksUpcomingHours: 4,
        inboxReminder: true,
        inboxReminderHours: 8,
        delegationsOverdue: true,
        delegationsOverdueDays: 2,
        morningSummary: true,
        morningSummaryTime: "08:00",
        weeklyReview: false,
        weeklyReviewTime: "17:00",
        meetingsUpcoming: true
    )
}
