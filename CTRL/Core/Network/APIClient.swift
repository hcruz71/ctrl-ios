import Foundation

/// URLSession wrapper for communicating with the CTRL NestJS backend.
/// All responses follow the `{ data, message, statusCode }` envelope.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Generic request

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: String? = nil,
        body: (any Encodable)? = nil
    ) async throws -> T {
        // Auto-determine HTTP method when not explicitly provided:
        //   body + collection → POST (create)
        //   body + single resource → PATCH (update)
        //   no body → endpoint default (GET)
        let httpMethod: String
        if let method {
            httpMethod = method
        } else if body != nil {
            httpMethod = endpoint.isCollection ? "POST" : "PATCH"
        } else {
            httpMethod = endpoint.method
        }

        var urlRequest = try endpoint.urlRequest(method: httpMethod)

        if let token = await AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let serverError = try? decoder.decode(APIEnvelope<EmptyData>.self, from: data)
            throw APIError.server(
                statusCode: http.statusCode,
                message: serverError?.message ?? "Error desconocido"
            )
        }

        let envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
        guard let payload = envelope.data else {
            throw APIError.emptyData
        }
        return payload
    }

    /// Fire-and-forget requests (DELETE, etc.) where we only care about success.
    func requestVoid(_ endpoint: APIEndpoint, body: (any Encodable)? = nil) async throws {
        let _: EmptyData? = try? await request(endpoint, method: "DELETE", body: body)
    }
}

// MARK: - Response envelope

struct APIEnvelope<T: Decodable>: Decodable {
    let data: T?
    let message: String
    let statusCode: Int
}

struct EmptyData: Decodable {}
