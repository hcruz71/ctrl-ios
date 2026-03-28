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
    case onboarding

    // MARK: - Objectives
    case objectives
    case objective(id: UUID)
    case objectiveKpi(id: UUID)
    case objectiveMeasurements(id: UUID)
    case objectivesTrash
    case objectiveRestore(id: UUID)
    case objectiveHardDelete(id: UUID)

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
    case meetingsAll
    case meetingsImported
    case meetingAttendance(id: UUID)
    case meetingScore(id: UUID)
    case meetingDelegate(id: UUID)
    case meetingsByDate(date: String)
    case meetingsAnalysis(period: String, startDate: String? = nil, endDate: String? = nil)

    // MARK: - Tasks
    case tasks
    case task(id: UUID)
    case taskPrepareEmail(id: UUID)
    case tasksToday
    case tasksInbox
    case tasksReorder
    case tasksTrash
    case taskRestore(id: UUID)
    case taskHardDelete(id: UUID)

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
    case projectTasks(id: UUID)
    case projectsTrash
    case projectRestore(id: UUID)
    case projectHardDelete(id: UUID)

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
    case gmailImport
    case gmailEmailsCount
    case gmailEmails(category: String? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil)
    case gmailEmail(id: String)
    case gmailAnalyze(hours: Int)
    case gmailAnalyzeMbox

    // MARK: - Help
    case helpArticles(lang: String, category: String? = nil)
    case helpArticle(id: String, lang: String)
    case helpFaqs(lang: String, category: String? = nil)
    case helpSearch(lang: String, query: String)
    case helpCategories

    // MARK: - Assistant
    case assistantChat

    // MARK: - Usage
    case usageSummary

    // MARK: - Trash
    case trashEmpty

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
        case .onboarding:         return "/auth/onboarding"
        case .objectives:         return "/objectives"
        case .objective(let id):                return "/objectives/\(id)"
        case .objectiveKpi(let id):             return "/objectives/\(id)/kpi"
        case .objectiveMeasurements(let id):    return "/objectives/\(id)/measurements"
        case .objectivesTrash:                  return "/objectives/trash"
        case .objectiveRestore(let id):         return "/objectives/\(id)/restore"
        case .objectiveHardDelete(let id):      return "/objectives/\(id)/hard"
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
        case .meetingsAll:               return "/meetings/all"
        case .meetingsImported:          return "/meetings/imported"
        case .meetingAttendance(let id): return "/meetings/\(id)/attendance"
        case .meetingScore(let id):      return "/meetings/\(id)/score"
        case .meetingDelegate(let id):   return "/meetings/\(id)/delegate"
        case .meetingsByDate(let date):  return "/meetings/date?date=\(date)"
        case .meetingsAnalysis(let p, let s, let e):
            var path = "/meetings/analysis?period=\(p)"
            if let s { path += "&startDate=\(s)" }
            if let e { path += "&endDate=\(e)" }
            return path
        case .tasks:              return "/tasks"
        case .task(let id):              return "/tasks/\(id)"
        case .taskPrepareEmail(let id):  return "/tasks/\(id)/prepare-email"
        case .tasksToday:         return "/tasks/today"
        case .tasksInbox:         return "/tasks/inbox"
        case .tasksReorder:       return "/tasks/reorder"
        case .tasksTrash:                return "/tasks/trash"
        case .taskRestore(let id):       return "/tasks/\(id)/restore"
        case .taskHardDelete(let id):    return "/tasks/\(id)/hard"
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
        case .projects:                       return "/projects"
        case .project(let id):                return "/projects/\(id)"
        case .projectSummary(let id):         return "/projects/\(id)/summary"
        case .projectTasks(let id):           return "/projects/\(id)/tasks"
        case .projectsTrash:                  return "/projects/trash"
        case .projectRestore(let id):         return "/projects/\(id)/restore"
        case .projectHardDelete(let id):      return "/projects/\(id)/hard"
        case .registerToken:             return "/push/register-token"
        case .revokeMcpToken:          return "/auth/mcp-token"
        case .googleCalendarAuth:               return "/google-calendar/auth"
        case .googleCalendarSync:               return "/google-calendar/sync"
        case .googleCalendarSyncAccount(let id): return "/google-calendar/sync/\(id)"
        case .googleCalendarStatus:             return "/google-calendar/status"
        case .googleCalendarAccounts:           return "/google-calendar/accounts"
        case .googleCalendarAccount(let id):    return "/google-calendar/accounts/\(id)"
        case .gmailImport:                         return "/google-calendar/gmail/import"
        case .gmailEmailsCount:                    return "/google-calendar/gmail/emails/count"
        case .gmailEmails(let cat, let lim, let off, let q):
            var p = "/google-calendar/gmail/emails?"
            var params: [String] = []
            if let cat { params.append("category=\(cat)") }
            if let lim { params.append("limit=\(lim)") }
            if let off { params.append("offset=\(off)") }
            if let q { params.append("search=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)") }
            return p + params.joined(separator: "&")
        case .gmailEmail(let id):                return "/google-calendar/gmail/emails/\(id)"
        case .gmailAnalyze(let hours):           return "/google-calendar/gmail/analyze?hours=\(hours)"
        case .gmailAnalyzeMbox:                  return "/google-calendar/gmail/analyze-mbox"
        case .helpArticles(let l, let c):
            var p = "/help/articles?lang=\(l)"
            if let c { p += "&category=\(c)" }
            return p
        case .helpArticle(let id, let l):    return "/help/articles/\(id)?lang=\(l)"
        case .helpFaqs(let l, let c):
            var p = "/help/faqs?lang=\(l)"
            if let c { p += "&category=\(c)" }
            return p
        case .helpSearch(let l, let q):      return "/help/search?lang=\(l)&q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)"
        case .helpCategories:                return "/help/categories"
        case .assistantChat:           return "/assistant/chat"
        case .usageSummary:              return "/usage/summary"
        case .trashEmpty:                return "/trash/empty"
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
        case .objectives, .meetings, .tasks, .delegations, .contacts, .login, .register, .loginApple, .loginGoogle, .registerToken, .revokeMcpToken, .assistantChat, .tasksToday, .tasksInbox, .tasksReorder, .tasksTrash, .taskRestore, .taskHardDelete, .updateMe, .onboarding, .processMinutes, .confirmTasks, .importICS, .meetingsToday, .meetingsUpcoming, .meetingsProductivity, .meetingsPast, .meetingsAll, .meetingsImported, .meetingAttendance, .meetingScore, .meetingDelegate, .meetingsByDate, .meetingsAnalysis, .sendDelegationEmail, .prepareDelegationEmail, .taskPrepareEmail, .googleCalendarAuth, .googleCalendarSync, .googleCalendarSyncAccount, .googleCalendarStatus, .googleCalendarAccounts, .gmailImport, .gmailEmailsCount, .gmailEmails, .gmailEmail, .gmailAnalyze, .gmailAnalyzeMbox, .schedule, .scheduleMode, .absences, .generateHandover, .objectiveKpi, .objectiveMeasurements, .objectivesTrash, .objectiveRestore, .objectiveHardDelete, .projects, .projectSummary, .projectTasks, .projectsTrash, .projectRestore, .projectHardDelete, .trashEmpty, .usageSummary, .subscriptionVerify, .subscriptionMe, .subscriptionPlans, .subscriptionRestore, .helpArticles, .helpArticle, .helpFaqs, .helpSearch, .helpCategories:
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
