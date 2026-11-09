import Foundation
import Testing
@testable import ComeetData

private final class MemoryPersistence: SessionPersistence, @unchecked Sendable {
    private let lock = NSLock()
    private var value: AuthSession?
    init(_ value: AuthSession? = nil) { self.value = value }
    func load() -> AuthSession? { lock.withLock { value } }
    func save(_ session: AuthSession?) { lock.withLock { value = session } }
}

private actor TestTransport: HTTPTransport {
    typealias Handler = @Sendable (URLRequest) async throws -> (Int, String)
    private var requests: [URLRequest] = []
    private let handler: Handler
    init(_ handler: @escaping Handler) { self.handler = handler }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let (status, body) = try await handler(request)
        return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
    func history() -> [URLRequest] { requests }
}

private let base = URL(string: "https://comeet.example.test")!
private let accountJSON = #"{"id":"11111111-1111-1111-1111-111111111111","email":"alex@example.test","emailConfirmed":true}"#
private let tokenJSON = #"{"accessToken":"renewed","refreshToken":"refresh-new","expiresIn":900}"#
private let profileJSON = #"{"id":"11111111-1111-1111-1111-111111111111","firstName":"Alex","lastName":"Example","birthdate":"2000-02-29","graduationYear":2026,"major":"Computing","bio":"Synthetic profile","matches":[],"attributes":[],"likedUserIds":[]}"#
private let messageJSON = #"{"id":3,"conversationId":1,"sender":"11111111-1111-1111-1111-111111111111","text":"Hello","createdAtUnixMilliseconds":1791568800123,"responseOptions":[]}"#
private func signedInStore() -> MemoryPersistence {
    MemoryPersistence(AuthSession(accessToken: "original", refreshToken: "refresh", expiresAt: .now.addingTimeInterval(900)))
}

@Test func signInPersistsTokensAndRegistrationUsesIdentityContracts() async throws {
    let store = MemoryPersistence()
    let transport = TestTransport { request in
        if request.url!.path.hasSuffix("register") { return (200, "") }
        return (200, tokenJSON)
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    try await client.signUp(email: "alex@example.test", password: "Synthetic123!")
    let requests = await transport.history()
    #expect(requests.map(\.httpMethod) == ["POST", "POST"])
    #expect(requests.map { $0.url!.path } == ["/api/auth/register", "/api/auth/login"])
    #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == nil })
    let body = try #require(requests[0].httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
    #expect(json["email"] == "alex@example.test")
    #expect(store.load()?.accessToken == "renewed")
}

@Test func passwordRecoveryUsesUnauthenticatedIdentityContractsAndPreservesSessionStorage() async throws {
    let store = signedInStore()
    let transport = TestTransport { _ in (200, "") }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    try await client.requestPasswordReset(email: "alex@example.test")
    try await client.resetPassword(email: "alex@example.test", resetCode: "synthetic-code_-", newPassword: "Replacement456!")
    let requests = await transport.history()
    #expect(requests.map { $0.url!.path } == ["/api/auth/forgotPassword", "/api/auth/resetPassword"])
    #expect(requests.allSatisfy { $0.httpMethod == "POST" && $0.value(forHTTPHeaderField: "Authorization") == nil && $0.url?.query == nil })
    let firstBody = try #require(requests[0].httpBody)
    let secondBody = try #require(requests[1].httpBody)
    let first = try #require(JSONSerialization.jsonObject(with: firstBody) as? [String: String])
    let second = try #require(JSONSerialization.jsonObject(with: secondBody) as? [String: String])
    #expect(first == ["email": "alex@example.test"])
    #expect(second == ["email": "alex@example.test", "resetCode": "synthetic-code_-", "newPassword": "Replacement456!"])
    #expect(store.load()?.accessToken == "original")
}

@Test func passwordRecoveryPropagatesInvalidCodeAndDeliveryFailures() async {
    let transport = TestTransport { request in
        request.url!.path.hasSuffix("forgotPassword") ? (503, #"{"detail":"Mail unavailable"}"#) : (400, #"{"errors":{"InvalidToken":["Invalid token."]}}"#)
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: MemoryPersistence())
    await #expect(throws: APIError.http(503, "Mail unavailable")) { try await client.requestPasswordReset(email: "alex@example.test") }
    await #expect(throws: APIError.http(400, "Invalid token.")) {
        try await client.resetPassword(email: "alex@example.test", resetCode: "invalid", newPassword: "Replacement456!")
    }
}

@Test func profileRoundTripUsesCamelCaseAndFlatIds() async throws {
    let transport = TestTransport { request in request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (200, profileJSON) }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    #expect(try await client.restoreSession())
    let fields = ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29", graduationYear: 2026, major: "Computing", bio: "Synthetic profile")
    let result = try await client.saveProfile(fields)
    #expect(result.firstName == "Alex")
    #expect(result.birthdate == "2000-02-29")
    #expect(result.matches.isEmpty && result.likedUserIds.isEmpty)
    let request = try #require(await transport.history().last)
    #expect(request.url!.path == "/api/users/me" && request.httpMethod == "PUT")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer original")
    let body = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["firstName"] as? String == "Alex")
    #expect(json["birthdate"] as? String == "2000-02-29")
    #expect(json["id"] == nil)
}

@Test func profileCreationIncludesGenderAndOnboardingAttributesWhileEditsOmitThem() async throws {
    let transport = TestTransport { request in request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (200, profileJSON) }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    let fields = ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29", graduationYear: 2026,
                               major: "Computing", bio: "Synthetic bio", gender: "Female",
                               attributes: [AttributeRecord(name: "raceEthnicity", importance: 3, value: "Synthetic background")])
    _ = try await client.saveProfile(fields)
    let firstRequest = try #require(await transport.history().last)
    let firstBody = try #require(firstRequest.httpBody)
    let firstJSON = try #require(JSONSerialization.jsonObject(with: firstBody) as? [String: Any])
    #expect(firstJSON["gender"] as? String == "Female")
    #expect((firstJSON["attributes"] as? [[String: Any]])?.first?["name"] as? String == "raceEthnicity")
    _ = try await client.saveProfile(ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29",
                                                  graduationYear: 2026, major: "Computing", bio: "Edited"))
    let editRequest = try #require(await transport.history().last)
    let editBody = try #require(editRequest.httpBody)
    let editJSON = try #require(JSONSerialization.jsonObject(with: editBody) as? [String: Any])
    #expect(editJSON["gender"] == nil && editJSON["attributes"] == nil)
}

@Test func attributesAreReplacedAndLikesHaveNoClientIdentity() async throws {
    let transport = TestTransport { request in
        if request.url!.path.hasSuffix("auth/me") { return (200, accountJSON) }
        if request.url!.path.hasSuffix("attributes") { return (200, String(data: request.httpBody!, encoding: .utf8)!) }
        return (200, #"{"conversationId":1}"#)
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    let values = [AttributeRecord(name: "Interests", importance: 3, value: "Reading")]
    #expect(try await client.saveAttributes(values) == values)
    let result = try await client.like(matchID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)
    #expect(result.conversationId == 1)
    let request = try #require(await transport.history().last)
    #expect(request.url!.path.hasSuffix("likes/22222222-2222-2222-2222-222222222222"))
    #expect(request.httpMethod == "POST" && request.httpBody == nil)
}

@Test func emptyConversationsAndIncrementalMessagesDecode() async throws {
    let transport = TestTransport { request in
        if request.url!.path.hasSuffix("auth/me") { return (200, accountJSON) }
        if request.url!.path.hasSuffix("messages") { return (200, "[\(messageJSON)]") }
        return (200, "[]")
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    #expect(try await client.conversations().isEmpty)
    let messages = try await client.messages(conversationID: 1, afterID: 2)
    #expect(messages.count == 1 && messages[0].text == "Hello")
    #expect(messages[0].timestamp.timeIntervalSince1970 > 0)
    let request = try #require(await transport.history().last)
    #expect(request.url!.query == "afterId=2")
}

@Test func messageWritesHaveIdempotencyAndNoSpoofableSender() async throws {
    let transport = TestTransport { request in request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (201, messageJSON) }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    let clientID = UUID()
    _ = try await client.sendMessage(conversationID: 1, replyToID: 2, text: "Hello", clientID: clientID)
    let request = try #require(await transport.history().last)
    let body = try #require(request.httpBody)
    let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["clientMessageId"] as? String == clientID.uuidString)
    #expect(json["replyToId"] as? Int == 2)
    #expect(json["sender"] == nil && json["public"] == nil && json["responseOptions"] == nil)
}

@Test func uploadUsesRawBytesAndStablePhotoURL() async throws {
    let transport = TestTransport { request in request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (204, "") }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    let bytes = Data([255, 216, 255, 217])
    try await client.uploadPhoto(bytes)
    let request = try #require(await transport.history().last)
    #expect(request.httpBody == bytes && request.httpMethod == "PUT")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
    #expect(client.photoURL(userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!).path == "/api/users/11111111-1111-1111-1111-111111111111/photo")
}

@Test func expiredSessionRefreshesAndUsesNewToken() async throws {
    let store = MemoryPersistence(AuthSession(accessToken: "expired", refreshToken: "refresh", expiresAt: .distantPast))
    let transport = TestTransport { request in request.url!.path.hasSuffix("refresh") ? (200, tokenJSON) : (200, accountJSON) }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    #expect(try await client.restoreSession())
    let requests = await transport.history()
    #expect(requests.count == 2)
    #expect(requests[0].value(forHTTPHeaderField: "Authorization") == nil)
    #expect(requests[1].value(forHTTPHeaderField: "Authorization") == "Bearer renewed")
    #expect(store.load()?.refreshToken == "refresh-new")
}

@Test func unauthorizedRetriesOnceAndClearsRevokedSession() async throws {
    let store = signedInStore()
    let transport = TestTransport { request in request.url!.path.hasSuffix("refresh") ? (200, tokenJSON) : (401, "") }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    #expect(try await !client.restoreSession())
    #expect(await transport.history().count == 3)
    #expect(store.load() == nil)
}

@Test func validationErrorsAndMissingProfilePropagate() async throws {
    let transport = TestTransport { request in
        if request.url!.path.hasSuffix("auth/me") { return (200, accountJSON) }
        return (400, #"{"title":"Validation failed","errors":{"Bio":["Too long"]}}"#)
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    await #expect(throws: APIError.http(400, "Too long")) { try await client.profile() }
}

@Test func deletionClearsTokensAndEmptyStoreNeverCallsNetwork() async throws {
    let store = signedInStore()
    let transport = TestTransport { request in request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (204, "") }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    _ = try await client.restoreSession()
    try await client.deleteAccount()
    #expect(store.load() == nil)
    #expect(try await !client.restoreSession())
    await #expect(throws: APIError.signedOut) { try await client.profile() }
    #expect(await transport.history().count == 2)
}

@Test func birthdaysRejectInvalidDatesAndRoundTripLeapDays() throws {
    #expect(try WireDates.birthday(WireDates.birthday("2000-02-29")) == "2000-02-29")
    #expect(throws: APIError.invalidResponse) { try WireDates.birthday("2001-02-29") }
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["COMEET_INTEGRATION_URL"] != nil))
func realAPIDataOperationsRoundTrip() async throws {
    let environment = ProcessInfo.processInfo.environment
    let address = try #require(environment["COMEET_INTEGRATION_URL"])
    let url = try #require(URL(string: address))
    let password = try #require(environment["COMEET_INTEGRATION_PASSWORD"])
    let alex = APIClient(baseURL: url, persistence: MemoryPersistence())
    let jordan = APIClient(baseURL: url, persistence: MemoryPersistence())
    try await alex.signIn(email: "alex@example.test", password: password)
    try await jordan.signIn(email: "jordan@example.test", password: password)
    let first = try await alex.profile()
    let second = try await jordan.profile()
    #expect(first.matches.contains { $0.id == second.id })
    let updated = try await alex.saveProfile(ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29", graduationYear: 2026, major: "Computing", bio: "Synthetic wire test"))
    #expect(updated.bio == "Synthetic wire test")
    let attributes = [AttributeRecord(name: "Interests", importance: 4, value: "Reading")]
    #expect(try await alex.saveAttributes(attributes) == attributes)
    _ = try await alex.like(matchID: second.id)
    let mutual = try await jordan.like(matchID: first.id)
    let conversationID = try #require(mutual.conversationId)
    #expect(try await alex.conversations().contains { $0.id == conversationID })
    let sent = try await alex.sendMessage(conversationID: conversationID, replyToID: nil, text: "Hello", clientID: UUID())
    let messages = try await jordan.messages(conversationID: conversationID, afterID: 0)
    #expect(messages.contains { $0.id == sent.id && $0.sender == first.id })
    let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==")!
    try await alex.uploadPhoto(png, contentType: "image/png")
    let (download, response) = try await URLSessionTransport().send(URLRequest(url: alex.photoURL(userID: first.id)))
    #expect(response.statusCode == 200 && download == png)
    try await alex.deleteAccount()
    try await jordan.deleteAccount()
    await #expect(throws: APIError.signedOut) { try await alex.profile() }
}

@Test func concurrentUnauthorizedRequestsShareOneRefresh() async throws {
    let transport = TestTransport { request in
        if request.url!.path.hasSuffix("refresh") {
            try await Task.sleep(for: .milliseconds(50))
            return (200, tokenJSON)
        }
        if request.url!.path.hasSuffix("users/me") && request.value(forHTTPHeaderField: "Authorization") == "Bearer original" { return (401, "") }
        return request.url!.path.hasSuffix("auth/me") ? (200, accountJSON) : (200, profileJSON)
    }
    let client = APIClient(baseURL: base, transport: transport, persistence: signedInStore())
    _ = try await client.restoreSession()
    try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<10 { group.addTask { _ = try await client.profile() } }
        try await group.waitForAll()
    }
    let refreshes = await transport.history().filter { $0.url!.path.hasSuffix("refresh") }
    #expect(refreshes.count == 1)
}

@Test func failedRefreshClearsPersistedSessionAndNetworkFailureRemainsRecoverable() async throws {
    let store = MemoryPersistence(AuthSession(accessToken: "expired", refreshToken: "refresh", expiresAt: .distantPast))
    let transport = TestTransport { _ in (401, "") }
    let client = APIClient(baseURL: base, transport: transport, persistence: store)
    #expect(try await !client.restoreSession())
    #expect(store.load() == nil)

    let offlineStore = signedInStore()
    let offline = APIClient(baseURL: base, transport: TestTransport { _ in throw URLError(.notConnectedToInternet) }, persistence: offlineStore)
    await #expect(throws: URLError.self) { try await offline.restoreSession() }
    #expect(offlineStore.load() != nil)
    await #expect(throws: URLError.self) { try await offline.signOut() }
    #expect(offlineStore.load() == nil)
}
