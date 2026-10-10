import Foundation

public actor APIClient: ComeetRepository {
    public nonisolated let baseURL: URL
    private let transport: any HTTPTransport
    private let persistence: any SessionPersistence
    private var session: AuthSession?
    private var refreshTask: Task<AuthSession, Error>?
    private var generation = 0

    public init(baseURL: URL, transport: any HTTPTransport = URLSessionTransport(), persistence: any SessionPersistence = KeychainSessionStore()) {
        self.baseURL = baseURL; self.transport = transport; self.persistence = persistence
    }

    public nonisolated func photoURL(userID: UUID) -> URL {
        baseURL.appending(path: "api/users/\(userID.uuidString.lowercased())/photo")
    }

    public func restoreSession() async throws -> Bool {
        session = try persistence.load()
        guard session != nil else { return false }
        do { _ = try await account(); return true }
        catch APIError.signedOut { try clearSession(); return false }
    }

    public func signUp(email: String, password: String) async throws {
        _ = try await request("api/auth/register", method: "POST", body: try encode(Credentials(email: email, password: password)), authenticated: false)
        try await signIn(email: email, password: password)
    }
    public func signIn(email: String, password: String) async throws {
        try clearSession()
        let currentGeneration = generation
        let data = try await request("api/auth/login", method: "POST", body: try encode(Credentials(email: email, password: password)), authenticated: false)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        guard currentGeneration == generation else { throw APIError.signedOut }
        try setSession(response.session)
    }
    public func signOut() async throws {
        // Clear local state even if the network is unavailable; the server revokes sessions when reachable.
        defer { try? clearSession() }
        _ = try await request("api/auth/logout", method: "POST")
    }
    public func account() async throws -> AccountInfo { try await get("api/auth/me") }
    public func resendConfirmation(email: String) async throws {
        _ = try await request("api/auth/resendConfirmationEmail", method: "POST", body: try encode(EmailRequest(email: email)), authenticated: false)
    }
    public func profile() async throws -> ProfileRecord { try await get("api/users/me") }
    public func saveProfile(_ fields: ProfileFields) async throws -> ProfileRecord {
        try decode(await request("api/users/me", method: "PUT", body: encode(fields)))
    }
    public func saveAttributes(_ attributes: [AttributeRecord]) async throws -> [AttributeRecord] {
        try decode(await request("api/users/me/attributes", method: "PUT", body: encode(attributes)))
    }
    public func like(matchID: UUID) async throws -> LikeRecord {
        try decode(await request("api/users/me/likes/\(matchID.uuidString.lowercased())", method: "POST"))
    }
    public func conversations() async throws -> [ConversationRecord] { try await get("api/conversations") }
    public func messages(conversationID: Int, afterID: Int = 0) async throws -> [MessageRecord] {
        try await get("api/conversations/\(conversationID)/messages", query: [URLQueryItem(name: "afterId", value: String(afterID))])
    }
    public func sendMessage(conversationID: Int, replyToID: Int?, text: String, clientID: UUID = UUID()) async throws -> MessageRecord {
        try decode(await request("api/conversations/\(conversationID)/messages", method: "POST",
            body: encode(MessageRequest(text: text, clientMessageID: clientID, replyToID: replyToID))))
    }
    public func uploadPhoto(_ data: Data, contentType: String = "image/jpeg") async throws {
        _ = try await request("api/users/me/photo", method: "PUT", body: data, contentType: contentType)
    }
    public func deleteAccount() async throws {
        _ = try await request("api/users/me", method: "DELETE")
        try clearSession()
    }

    private func get<T: Decodable & Sendable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try decode(await request(path, query: query))
    }
    private func encode<T: Encodable>(_ value: T) throws -> Data { try JSONEncoder().encode(value) }
    private func decode<T: Decodable>(_ data: Data) throws -> T { try WireDates.decoder().decode(T.self, from: data) }
    private func setSession(_ value: AuthSession) throws { try persistence.save(value); session = value }
    private func clearSession() throws {
        generation += 1; refreshTask?.cancel(); refreshTask = nil; session = nil
        try persistence.save(nil)
    }

    private func accessToken() async throws -> String {
        guard let session else { throw APIError.signedOut }
        if session.expiresAt.timeIntervalSinceNow > 30 { return session.accessToken }
        return try await refresh().accessToken
    }
    private func refresh() async throws -> AuthSession {
        if let refreshTask { return try await refreshTask.value }
        guard let previous = session else { throw APIError.signedOut }
        let currentGeneration = generation
        let task = Task {
            let data = try await self.request("api/auth/refresh", method: "POST", body: self.encode(RefreshRequest(refreshToken: previous.refreshToken)), authenticated: false)
            let value = try JSONDecoder().decode(TokenResponse.self, from: data).session
            guard currentGeneration == self.generation else { throw APIError.signedOut }
            // Commit before completing the shared task: every waiter must observe the new token.
            try self.setSession(value)
            return value
        }
        refreshTask = task
        do {
            let value = try await task.value
            guard currentGeneration == generation else { throw APIError.signedOut }
            refreshTask = nil
            return value
        } catch {
            if currentGeneration == generation {
                refreshTask = nil
                if case APIError.http(401, _) = error { try clearSession(); throw APIError.signedOut }
            }
            throw error
        }
    }

    private func request(_ path: String, method: String = "GET", body: Data? = nil, contentType: String = "application/json",
                         query: [URLQueryItem] = [], authenticated: Bool = true, retry: Bool = true) async throws -> Data {
        let currentGeneration = generation
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        var request = URLRequest(url: url)
        request.httpMethod = method; request.httpBody = body; request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        var sentToken: String?
        if authenticated {
            sentToken = try await accessToken()
            request.setValue("Bearer \(sentToken!)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await transport.send(request)
        if authenticated, currentGeneration != generation { throw APIError.signedOut }
        if response.statusCode == 401 && authenticated {
            if retry {
                if session?.accessToken == sentToken { _ = try await refresh() }
                return try await self.request(path, method: method, body: body, contentType: contentType, query: query, authenticated: true, retry: false)
            }
            try clearSession(); throw APIError.signedOut
        }
        guard (200..<300).contains(response.statusCode) else {
            let problem = try? JSONDecoder().decode(Problem.self, from: data)
            let message = problem?.errors?.sorted(by: { $0.key < $1.key }).flatMap(\.value).joined(separator: " ")
            throw APIError.http(response.statusCode, message?.isEmpty == false ? message! : problem?.detail ?? problem?.title ?? "Request failed (\(response.statusCode)).")
        }
        return data
    }
}

private struct Credentials: Encodable { let email: String; let password: String }
private struct RefreshRequest: Encodable { let refreshToken: String }
private struct EmailRequest: Encodable { let email: String }
private struct TokenResponse: Decodable {
    let accessToken: String; let refreshToken: String; let expiresIn: Int
    var session: AuthSession { AuthSession(accessToken: accessToken, refreshToken: refreshToken, expiresAt: .now.addingTimeInterval(Double(expiresIn))) }
}
private struct MessageRequest: Encodable {
    let text: String; let clientMessageID: UUID; let replyToID: Int?
    enum CodingKeys: String, CodingKey { case text; case clientMessageID = "client_message_id", replyToID = "reply_to_id" }
}
private struct Problem: Decodable { let title: String?; let detail: String?; let errors: [String: [String]]? }
