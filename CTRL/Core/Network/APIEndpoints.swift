import Foundation

enum APIEndpoint {
    // MARK: - Configuration
    static let baseURL = "https://ctrl-api-b8562ac8a00a.herokuapp.com"

    // MARK: - Auth / User
    case login
    case register
    case loginApple
    case loginGoogle
    case me
    case updateMe

    // MARK: - Objectives
    case objectives
    case objective(id: UUID)
    case objectiveKpi(id: UUID)
    case objectiveMeasurements(id: UUID)

    // MARK: - Meetings
    case meetings
    case meeting(id: UUID)
    case meetingObjective(id: UUID)
    case processMinutes
    case confirmTasks
    case importICS
    case meetingsToday
    case meetingsUpcoming
    case meetingsProductivity
    case meetingsPast
    case meetingAttendance(id: UUID)
    case meetingScore(id: UUID)
    case meetingDelegate(id: UUID)
    case meetingsByDate(date: String)

    // MARK: - Tasks
    case tasks
    case task(id: UUID)
    case tasksToday
    case tasksInbox
    case tasksReorder

    // MARK: - Delegations
    case delegations
    case delegation(id: UUID)
    case sendDelegationEmail(id: UUID)
    case prepareDelegationEmail(id: UUID)

    // MARK: - Contacts
    case contacts
    case contact(id: UUID)

    // MARK: - Schedule & Absences
    case schedule
    case scheduleMode
    case absences
    case absence(id: UUID)
    case generateHandover(id: UUID)

    // MARK: - Projects
    case projects
    case project(id: UUID)
    case projectSummary(id: UUID)

    // MARK: - Push
    case registerToken

    // MARK: - MCP
    case revokeMcpToken

    // MARK: - Google Calendar
    case googleCalendarAuth
    case googleCalendarSync
    case googleCalendarSyncAccount(id: UUID)
    case googleCalendarStatus
    case googleCalendarAccounts
    case googleCalendarAccount(id: UUID)

    // MARK: - Assistant
    case assistantChat

    // MARK: - Usage
    case usageSummary

    // MARK: - Subscriptions
    case subscriptionVerify
    case subscriptionMe
    case subscriptionPlans
    case subscriptionRestore

    // MARK: - URL building

    var path: String {
        switch self {
        case .login:              return "/auth/login"
        case .register:           return "/auth/register"
        case .loginApple:             return "/auth/apple"
        case .loginGoogle:            return "/auth/google-login"
        case .me:                 return "/auth/me"
        case .updateMe:           return "/users/me"
        case .objectives:         return "/objectives"
        case .objective(let id):                return "/objectives/\(id)"
        case .objectiveKpi(let id):             return "/objectives/\(id)/kpi"
        case .objectiveMeasurements(let id):    return "/objectives/\(id)/measurements"
        case .meetings:                  return "/meetings"
        case .meeting(let id):           return "/meetings/\(id)"
        case .meetingObjective(let id):  return "/meetings/\(id)/objective"
        case .processMinutes:            return "/meetings/process-minutes"
        case .confirmTasks:              return "/meetings/confirm-tasks"
        case .importICS:                 return "/meetings/import-ics"
        case .meetingsToday:             return "/meetings/today"
        case .meetingsUpcoming:          return "/meetings/upcoming"
        case .meetingsProductivity:      return "/meetings/productivity"
        case .meetingsPast:              return "/meetings/past"
        case .meetingAttendance(let id): return "/meetings/\(id)/attendance"
        case .meetingScore(let id):      return "/meetings/\(id)/score"
        case .meetingDelegate(let id):   return "/meetings/\(id)/delegate"
        case .meetingsByDate(let date):  return "/meetings/date?date=\(date)"
        case .tasks:              return "/tasks"
        case .task(let id):       return "/tasks/\(id)"
        case .tasksToday:         return "/tasks/today"
        case .tasksInbox:         return "/tasks/inbox"
        case .tasksReorder:       return "/tasks/reorder"
        case .delegations:                   return "/delegations"
        case .delegation(let id):            return "/delegations/\(id)"
        case .sendDelegationEmail(let id):      return "/delegations/\(id)/send-email"
        case .prepareDelegationEmail(let id):  return "/delegations/\(id)/prepare-email"
        case .contacts:           return "/contacts"
        case .contact(let id):    return "/contacts/\(id)"
        case .schedule:                  return "/schedule"
        case .scheduleMode:              return "/schedule/mode"
        case .absences:                  return "/schedule/absences"
        case .absence(let id):           return "/schedule/absences/\(id)"
        case .generateHandover(let id):  return "/schedule/absences/\(id)/generate-documents"
        case .projects:                  return "/projects"
        case .project(let id):           return "/projects/\(id)"
        case .projectSummary(let id):    return "/projects/\(id)/summary"
        case .registerToken:             return "/push/register-token"
        case .revokeMcpToken:          return "/auth/mcp-token"
        case .googleCalendarAuth:               return "/google-calendar/auth"
        case .googleCalendarSync:               return "/google-calendar/sync"
        case .googleCalendarSyncAccount(let id): return "/google-calendar/sync/\(id)"
        case .googleCalendarStatus:             return "/google-calendar/status"
        case .googleCalendarAccounts:           return "/google-calendar/accounts"
        case .googleCalendarAccount(let id):    return "/google-calendar/accounts/\(id)"
        case .assistantChat:           return "/assistant/chat"
        case .usageSummary:              return "/usage/summary"
        case .subscriptionVerify:        return "/subscriptions/verify"
        case .subscriptionMe:            return "/subscriptions/me"
        case .subscriptionPlans:         return "/subscriptions/plans"
        case .subscriptionRestore:       return "/subscriptions/restore"
        }
    }

    var method: String {
        switch self {
        case .login, .register, .loginApple, .loginGoogle:
            return "POST"
        default:
            return "GET"
        }
    }

    /// Whether this endpoint targets a collection (no id) vs a single resource.
    var isCollection: Bool {
        switch self {
        case .objectives, .meetings, .tasks, .delegations, .contacts, .login, .register, .loginApple, .loginGoogle, .registerToken, .revokeMcpToken, .assistantChat, .tasksToday, .tasksInbox, .tasksReorder, .updateMe, .processMinutes, .confirmTasks, .importICS, .meetingsToday, .meetingsUpcoming, .meetingsProductivity, .meetingsPast, .meetingAttendance, .meetingScore, .meetingDelegate, .meetingsByDate, .sendDelegationEmail, .prepareDelegationEmail, .googleCalendarAuth, .googleCalendarSync, .googleCalendarSyncAccount, .googleCalendarStatus, .googleCalendarAccounts, .schedule, .scheduleMode, .absences, .generateHandover, .objectiveKpi, .objectiveMeasurements, .projects, .projectSummary, .usageSummary, .subscriptionVerify, .subscriptionMe, .subscriptionPlans, .subscriptionRestore:
            return true
        default:
            return false
        }
    }

    func urlRequest(method override: String? = nil) throws -> URLRequest {
        guard let url = URL(string: Self.baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = override ?? self.method
        return request
    }
}

// Convenience helpers for CRUD verbs
extension APIEndpoint {
    static func get(_ endpoint: APIEndpoint) throws -> URLRequest {
        try endpoint.urlRequest(method: "GET")
    }
    static func post(_ endpoint: APIEndpoint) throws -> URLRequest {
        try endpoint.urlRequest(method: "POST")
    }
    static func patch(_ endpoint: APIEndpoint) throws -> URLRequest {
        try endpoint.urlRequest(method: "PATCH")
    }
    static func delete(_ endpoint: APIEndpoint) throws -> URLRequest {
        try endpoint.urlRequest(method: "DELETE")
    }
}
