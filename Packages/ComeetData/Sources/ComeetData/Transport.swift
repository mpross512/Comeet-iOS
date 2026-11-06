import Foundation

public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        return (data, response)
    }
}

public enum APIError: Error, LocalizedError, Sendable, Equatable {
    case invalidResponse
    case signedOut
    case http(Int, String)
    case keychain(Int32)
    public var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response."
        case .signedOut: "Please sign in again."
        case .http(_, let detail): detail
        case .keychain: "Your session could not be stored securely."
        }
    }
}

public struct AuthSession: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken; self.refreshToken = refreshToken; self.expiresAt = expiresAt
    }
}

public protocol SessionPersistence: Sendable {
    func load() throws -> AuthSession?
    func save(_ session: AuthSession?) throws
}
