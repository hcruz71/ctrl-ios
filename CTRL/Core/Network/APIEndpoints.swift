import Foundation

enum APIEndpoint {
    // MARK: - Configuration
    static let baseURL = "https://ctrl-api-b8562ac8a00a.herokuapp.com"

    // MARK: - Auth
    case login
    case register
    case me

    // MARK: - Objectives
    case objectives
    case objective(id: UUID)

    // MARK: - Meetings
    case meetings
    case meeting(id: UUID)

    // MARK: - Tasks
    case tasks
    case task(id: UUID)
    case tasksToday
    case tasksInbox
    case tasksReorder

    // MARK: - Delegations
    case delegations
    case delegation(id: UUID)

    // MARK: - Contacts
    case contacts
    case contact(id: UUID)

    // MARK: - Push
    case registerToken

    // MARK: - MCP
    case revokeMcpToken

    // MARK: - Assistant
    case assistantChat

    // MARK: - URL building

    var path: String {
        switch self {
        case .login:              return "/auth/login"
        case .register:           return "/auth/register"
        case .me:                 return "/auth/me"
        case .objectives:         return "/objectives"
        case .objective(let id):  return "/objectives/\(id)"
        case .meetings:           return "/meetings"
        case .meeting(let id):    return "/meetings/\(id)"
        case .tasks:              return "/tasks"
        case .task(let id):       return "/tasks/\(id)"
        case .tasksToday:         return "/tasks/today"
        case .tasksInbox:         return "/tasks/inbox"
        case .tasksReorder:       return "/tasks/reorder"
        case .delegations:        return "/delegations"
        case .delegation(let id): return "/delegations/\(id)"
        case .contacts:           return "/contacts"
        case .contact(let id):    return "/contacts/\(id)"
        case .registerToken:      return "/push/register-token"
        case .revokeMcpToken:     return "/auth/mcp-token"
        case .assistantChat:      return "/assistant/chat"
        }
    }

    var method: String {
        switch self {
        case .login, .register:
            return "POST"
        default:
            return "GET"
        }
    }

    /// Whether this endpoint targets a collection (no id) vs a single resource.
    var isCollection: Bool {
        switch self {
        case .objectives, .meetings, .tasks, .delegations, .contacts, .login, .register, .registerToken, .revokeMcpToken, .assistantChat, .tasksToday, .tasksInbox, .tasksReorder:
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
