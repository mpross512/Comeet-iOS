import Foundation
import Testing
import ComeetData
import UIKit
import SDWebImage
@testable import Comeet

private actor AdapterRepository: ComeetRepository {
    var savedFields: ProfileFields?
    var savedAttributes: [AttributeRecord] = []
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
    func account() throws -> AccountInfo { try JSONDecoder().decode(AccountInfo.self, from: Data(adapterAccount.utf8)) }
    func resendConfirmation(email: String) { }
    func profile() throws -> ProfileRecord {
        if missingProfile { throw APIError.http(404, "Not found") }
        var json = try #require(JSONSerialization.jsonObject(with: Data(adapterProfile.utf8)) as? [String: Any])
        if let savedFields {
            let fields = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(savedFields)) as? [String: Any])
            json.merge(fields) { _, saved in saved }
        }
        json["attributes"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(savedAttributes))
        return try JSONDecoder().decode(ProfileRecord.self, from: JSONSerialization.data(withJSONObject: json))
    }
    func saveProfile(_ fields: ProfileFields) throws -> ProfileRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        missingProfile = false
        savedFields = fields
        return try profile()
    }
    func saveAttributes(_ attributes: [AttributeRecord]) throws -> [AttributeRecord] {
        if failWrites { throw APIError.http(503, "Unavailable") }
        savedAttributes = attributes
        return attributes
    }
    func like(matchID: UUID) throws -> LikeRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        liked = matchID
        return try JSONDecoder().decode(LikeRecord.self, from: Data(#"{"conversationId":null}"#.utf8))
    }
    func conversations() throws -> [ConversationRecord] {
        try JSONDecoder().decode([ConversationRecord].self, from: Data(adapterConversations.utf8))
    }
    func messages(conversationID: Int, afterID: Int) -> [MessageRecord] { pages.isEmpty ? [] : pages.removeFirst() }
    func sendMessage(conversationID: Int, replyToID: Int?, text: String, clientID: UUID) throws -> MessageRecord {
        if failWrites { throw APIError.http(503, "Unavailable") }
        sentText = text
        return try JSONDecoder().decode(MessageRecord.self, from: Data(adapterMessage.utf8))
    }
    func uploadPhoto(_ data: Data, contentType: String) throws { if failWrites { throw APIError.http(503, "Unavailable") } }
    func deleteAccount() { restoredSession = false }
}
private let adapterAccount = #"{"id":"11111111-1111-1111-1111-111111111111","email":"alex@example.test","emailConfirmed":true}"#
private let adapterProfile = #"{"id":"11111111-1111-1111-1111-111111111111","firstName":"Alex","lastName":"Example","birthdate":"2000-02-29","graduationYear":2026,"major":"Computing","bio":"Synthetic profile","matches":[{"id":"22222222-2222-2222-2222-222222222222","firstName":"Jordan","lastName":"Example","birthdate":"2000-10-31","graduationYear":2026,"major":"Computing","bio":"Synthetic match","attributes":[{"name":"Interests","importance":3,"value":"Reading"}]}],"attributes":[],"likedUserIds":["22222222-2222-2222-2222-222222222222"]}"#
private let adapterConversations = #"[{"id":1,"peer":{"id":"22222222-2222-2222-2222-222222222222","firstName":"Jordan","lastName":"Example"},"messages":[]}]"#
private let adapterMessage = #"{"id":3,"conversationId":1,"sender":"11111111-1111-1111-1111-111111111111","text":"Hello","createdAtUnixMilliseconds":1791568800000,"responseOptions":[]}"#

@Test @MainActor func profileAdapterPreservesRelationshipsAndMatchAttributes() async throws {
    let repository = AdapterRepository()
    let user = try User(record: await repository.profile())
    #expect(user.firstName == "Alex" && user.likes.count == 1)
    #expect(user.matches.first?.attributes.first?.value == "Reading")
    let match = try #require(user.matches.first)
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
    let message = try JSONDecoder().decode(MessageRecord.self, from: Data(adapterMessage.utf8))
    await repository.configure(pages: [[message], [message]])
    let conversations = try await Conversation.all(repository: repository)
    let conversation = try #require(conversations.first)
    #expect(conversation.peer.id == UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
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

@Test @MainActor func profileEditsAndAttributesRemainCurrentAfterReload() async throws {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let oldUser = session.currentUser
    let fields = ProfileFields(firstName: "Taylor", lastName: "Example", birthdate: "2001-03-04",
                               graduationYear: 2028, major: "Arts", bio: "Updated bio")
    try await session.saveProfile(fields)
    // Display views must consume the replacement input rather than retain oldUser in @State.
    let bio = UserBio(user: session.currentUser)
    #expect(bio.user.fullName == "Taylor Example")
    #expect(bio.user.bio == "Updated bio" && bio.user.major == "Arts")
    #expect(bio.user.graduationYear == 2028 && WireDates.birthday(bio.user.birthdate) == "2001-03-04")
    #expect(session.currentUser !== oldUser)
    try await session.saveAttributes([Attribute(name: "Interests", importance: 4, value: "Music")])
    #expect(session.currentUser.attributes.first?.value == "Music")
    try await session.reloadProfile()
    #expect(session.currentUser.bio == "Updated bio")
    #expect(session.currentUser.attributes.first?.value == "Music")
    #expect(session.currentUser.matches.count == 1 && session.currentUser.likes.count == 1)

    await repository.configure(fail: true)
    await #expect(throws: APIError.http(503, "Unavailable")) { try await session.saveProfile(fields) }
    await #expect(throws: APIError.http(503, "Unavailable")) { try await session.saveAttributes([]) }
    #expect(session.currentUser.bio == "Updated bio" && session.currentUser.attributes.count == 1)
}

@Test @MainActor func photoUploadReplacesOnlyOwnerCachesWithStableURL() async throws {
    let repository = AdapterRepository()
    let imageCache = SDImageCache(namespace: "photo-tests-\(UUID().uuidString)")
    let httpCache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0)
    let session = SessionStore(repository: repository,
                               photoCache: ProfilePhotoCache(imageCache: imageCache, httpCache: httpCache))
    await session.restore()
    let ownerURL = APIConfiguration.photoURL(userID: session.currentUser.id)
    let peerURL = APIConfiguration.photoURL(userID: try #require(session.currentUser.matches.first?.id))
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
    let oldImage = renderer.image { context in
        UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
    let newImage = renderer.image { context in
        UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
    let data = try #require(newImage.jpegData(compressionQuality: 0.8))
    for url in [ownerURL, peerURL] {
        imageCache.storeImage(toMemory: oldImage, forKey: url.absoluteString)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                                  headerFields: ["Cache-Control": "max-age=60"]))
        httpCache.storeCachedResponse(CachedURLResponse(response: response, data: Data([1])), for: URLRequest(url: url))
    }
    let originalRevision = session.profilePhotoRevision
    try await session.uploadPhoto(data)
    #expect(APIConfiguration.photoURL(userID: session.currentUser.id) == ownerURL)
    #expect(ownerURL.query == nil)
    #expect(session.profilePhotoRevision != originalRevision)
    #expect(imageCache.imageFromMemoryCache(forKey: ownerURL.absoluteString)?.jpegData(compressionQuality: 0.8) != oldImage.jpegData(compressionQuality: 0.8))
    #expect(imageCache.diskImageData(forKey: ownerURL.absoluteString) == data)
    #expect(httpCache.cachedResponse(for: URLRequest(url: ownerURL)) == nil)
    #expect(imageCache.imageFromMemoryCache(forKey: peerURL.absoluteString) === oldImage)
    #expect(httpCache.cachedResponse(for: URLRequest(url: peerURL))?.data == Data([1]))

    let updatedRevision = session.profilePhotoRevision
    try await session.reloadProfile()
    #expect(session.profilePhotoRevision == updatedRevision)
    await repository.configure(fail: true)
    await #expect(throws: APIError.http(503, "Unavailable")) { try await session.uploadPhoto(try #require(oldImage.jpegData(compressionQuality: 0.8))) }
    #expect(session.profilePhotoRevision == updatedRevision)
    #expect(imageCache.diskImageData(forKey: ownerURL.absoluteString) == data)
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        imageCache.clearDisk { continuation.resume() }
    }
}
