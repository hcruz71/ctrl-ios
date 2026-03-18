import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case emptyData
    case server(statusCode: Int, message: String)
    case unauthorized
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .invalidResponse:
            return "Respuesta del servidor inválida."
        case .emptyData:
            return "No se recibieron datos."
        case .server(_, let message):
            return message
        case .unauthorized:
            return "Sesión expirada. Inicia sesión de nuevo."
        case .decodingFailed(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        }
    }

    var isUnauthorized: Bool {
        if case .server(let code, _) = self, code == 401 { return true }
        if case .unauthorized = self { return true }
        return false
    }
}
