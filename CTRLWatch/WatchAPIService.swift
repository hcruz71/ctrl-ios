import Foundation

enum WatchAPIError: LocalizedError {
    case notAuthenticated
    case requestFailed(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "No autenticado"
        case .requestFailed(let code): return "Error \(code)"
        case .decodingFailed: return "Error de datos"
        }
    }
}

/// Standalone HTTP client for watchOS — calls the backend directly
/// without proxying through the iPhone via WatchConnectivity.
final class WatchAPIService {
    static let shared = WatchAPIService()
    private let baseURL = "https://ctrl-api-b8562ac8a00a.herokuapp.com"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    var token: String? {
        UserDefaults.standard.string(forKey: "watchAuthToken")
    }

    var isAuthenticated: Bool { token != nil }

    /// Generic request that unwraps the API envelope `{ data, message, statusCode }`.
    func request<T: Decodable>(_ path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> T {
        guard let token else { throw WatchAPIError.notAuthenticated }
        guard let url = URL(string: baseURL + path) else { throw WatchAPIError.requestFailed(0) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw WatchAPIError.requestFailed(code)
        }

        // Unwrap API envelope
        let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
        guard let payload = envelope.data else { throw WatchAPIError.decodingFailed }
        return payload
    }
}

private struct APIEnvelope<T: Decodable>: Decodable {
    let data: T?
}
