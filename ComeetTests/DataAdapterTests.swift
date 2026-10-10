import Foundation
import Testing
import ComeetData
@testable import Comeet

private actor AdapterRepository: ComeetRepository {
    var missingProfile = false
    var restoredSession = true
    var failWrites = false
    var liked: UUID?
    var sentText: String?
    var pages: [[MessageRecord]] = []
    func configure(missing: Bool = false, restored: Bool = true, fail: Bool = false, pages: [[MessageRecord]] = []) {
        missingProfile = missing; restoredSession = restored; failWrites = fail; self.pages = pages
    }
    func restoreSession() -> Bool { restoredSession }
    func signUp(email: String, password: String) { }
    func signIn(email: String, password: String) { }
    func signOut() { restoredSession = false }
    func account() throws -> AccountInfo { try WireDates.decoder().decode(AccountInfo.self, from: Data(adapterAccount.utf8)) }
    func resendConfirmation(email: String) { }
    func profile() throws -> ProfileRecord {
        if missingProfile { throw APIError.http(404, "Not found") }
        return try WireDates.decoder().decode(ProfileRecord.self, from: Data(adapterProfile.utf8))
    }
    func saveProfile(_ fields: ProfileFields) throws -> ProfileRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        missingProfile = false
        return try profile()
    }
    func saveAttributes(_ attributes: [AttributeRecord]) throws -> [AttributeRecord] {
        if failWrites { throw APIError.http(503, "Unavailable") }
        return attributes
    }
    func like(matchID: UUID) throws -> LikeRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        liked = matchID
        return try JSONDecoder().decode(LikeRecord.self, from: Data(#"{"conversation_id":null}"#.utf8))
    }
    func conversations() throws -> [ConversationRecord] {
        try WireDates.decoder().decode([ConversationRecord].self, from: Data(adapterConversations.utf8))
    }
    func messages(conversationID: Int, afterID: Int) -> [MessageRecord] { pages.isEmpty ? [] : pages.removeFirst() }
    func sendMessage(conversationID: Int, replyToID: Int?, text: String, clientID: UUID) throws -> MessageRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        sentText = text
        return try WireDates.decoder().decode(MessageRecord.self, from: Data(adapterMessage.utf8))
    }
    func uploadPhoto(_ data: Data, contentType: String) throws { if failWrites { throw APIError.http(503, "Unavailable") } }
    func deleteAccount() { restoredSession = false }
}
private let adapterAccount = #"{"id":"11111111-1111-1111-1111-111111111111","email":"alex@example.test","email_confirmed":true}"#
private let adapterProfile = #"{"id":"11111111-1111-1111-1111-111111111111","first_name":"Alex","last_name":"Example","birthdate":"2000-02-29","graduation_year":2026,"major":"Computing","bio":"Synthetic profile","user_matches":[{"id":"22222222-2222-2222-2222-222222222222","first_name":"Jordan","last_name":"Example","birthdate":"2000-10-31","graduation_year":2026,"major":"Computing","bio":"Synthetic match","attributes":[{"name":"Interests","importance":3,"value":"Reading"}]}],"v_user_attributes":[],"user_likes":[{"id":"22222222-2222-2222-2222-222222222222"}],"conversations":[{"id":1}]}"#
private let adapterConversations = #"[{"id":1,"conversation_members":[{"member_id":"11111111-1111-1111-1111-111111111111"},{"member_id":"22222222-2222-2222-2222-222222222222"}],"messages":[]}]"#
private let adapterMessage = #"{"id":3,"conversation_id":1,"sender":"11111111-1111-1111-1111-111111111111","text":"Hello","created_at":"2026-10-09T18:00:00Z","response_option":[],"public":true}"#

@Test @MainActor func profileAdapterPreservesRelationshipsAndMatchAttributes() async throws {
    let repository = AdapterRepository()
    let user = try User(record: await repository.profile())
    #expect(user.firstName == "Alex" && user.likes.count == 1)
    #expect(user.conversations == ["1"])
    #expect(user.matches.first?.attributes.first?.value == "Reading")
    let data = try JSONEncoder().encode(user.matches[0])
    let match = try JSONDecoder().decode(Match.self, from: data)
    #expect(WireDates.birthday(match.birthdate) == "2000-10-31")
}

@Test @MainActor func onboardingRecognizesMissingProfileAndSessionRestorationLoadsUser() async throws {
    let repository = AdapterRepository()
    await repository.configure(missing: true)
    let session = SessionStore(repository: repository)
    await session.restore()
    #expect(session.authenticated && session.restored && session.needsProfile)
    try await session.saveProfile(ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29", graduationYear: 2026, major: "Computing", bio: ""))
    #expect(!session.needsProfile && session.currentUser.firstName == "Alex")
}

@Test @MainActor func signOutAndDeletionRemoveUserStateAcrossAccounts() async throws {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    #expect(session.currentUser.likes.count == 1)
    try await session.signOut()
    #expect(!session.authenticated && session.currentUser.likes.isEmpty && session.currentUser.firstName.isEmpty)
    try await session.signIn(email: "alex@example.test", password: "Synthetic123!")
    try await session.deleteAccount()
    #expect(!session.authenticated && session.currentUser.conversations.isEmpty)
}

@Test @MainActor func failedProfileWriteDoesNotCompleteOnboarding() async throws {
    let repository = AdapterRepository()
    await repository.configure(missing: true, fail: true)
    let session = SessionStore(repository: repository)
    await session.restore()
    await #expect(throws: APIError.http(503, "Unavailable")) {
        try await session.saveProfile(ProfileFields(firstName: "Alex", lastName: "Example", birthdate: "2000-02-29", graduationYear: 2026, major: "Computing", bio: ""))
    }
    #expect(session.needsProfile)
}

@Test @MainActor func conversationPollingUsesMembersAndDeduplicatesUpdates() async throws {
    let repository = AdapterRepository()
    let message = try WireDates.decoder().decode(MessageRecord.self, from: Data(adapterMessage.utf8))
    await repository.configure(pages: [[message], [message]])
    let conversations = try await Conversation.all(userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, repository: repository)
    let conversation = try #require(conversations.first)
    #expect(conversation.recipientID == UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    try await conversation.refresh(repository: repository)
    try await conversation.refresh(repository: repository)
    #expect(conversation.messages.count == 1 && conversation.messages[0].text == "Hello")
}

@Test @MainActor func serviceAdaptersPropagateWriteFailures() async throws {
    let repository = AdapterRepository()
    await repository.configure(fail: true)
    let users = UserService(repository: repository)
    #expect(await !users.likeUser(userID: UUID(), matchID: UUID()))
    #expect(users.errorMessage == "Unavailable")
    await #expect(throws: APIError.http(503, "Unavailable")) { try await users.uploadNewImage(data: Data()) }
    let messages = MessageService(repository: repository)
    await #expect(throws: APIError.http(503, "Unavailable")) { try await messages.addMessage(conversationID: 1, messageID: 2, response: "Hello") }
}

@Test func nativeKeychainSessionPersistsUpdatesAndDeletes() throws {
    let store = KeychainSessionStore(service: "com.Comeet.test.\(UUID().uuidString)")
    defer { try? store.save(nil) }
    #expect(try store.load() == nil)
    try store.save(AuthSession(accessToken: "synthetic-first", refreshToken: "synthetic-refresh", expiresAt: .now.addingTimeInterval(900)))
    #expect(try store.load()?.accessToken == "synthetic-first")
    try store.save(AuthSession(accessToken: "synthetic-second", refreshToken: "synthetic-new-refresh", expiresAt: .now.addingTimeInterval(900)))
    #expect(try store.load()?.refreshToken == "synthetic-new-refresh")
    try store.save(nil)
    #expect(try store.load() == nil)
}
