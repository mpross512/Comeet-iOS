import Foundation
import Testing
import ComeetData
import UIKit
import SDWebImage
@testable import Comeet

private actor AdapterRepository: ComeetRepository {
    var accountRefreshError: (any Error & Sendable)?
    var profileRefreshError: (any Error & Sendable)?
    func configureRefreshError(_ error: (any Error & Sendable)?, duringProfile: Bool = false) {
        accountRefreshError = duringProfile ? nil : error
        profileRefreshError = duringProfile ? error : nil
    }
    var accountID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    var confirmed = true
    var photoWrites = 0
    func configureAccount(id: UUID, confirmed: Bool) { accountID = id; self.confirmed = confirmed }
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
    func account() throws -> AccountInfo {
        if let accountRefreshError { throw accountRefreshError }
        let data = try JSONSerialization.data(withJSONObject: ["id": accountID.uuidString, "email": "alex@example.test", "emailConfirmed": confirmed])
        return try JSONDecoder().decode(AccountInfo.self, from: data)
    }
    func resendConfirmation(email: String) { }
    var recoveryFailure: APIError?
    var recoveryRequests = 0
    var passwordResets = 0
    var resetEmail: String?
    var submittedResetCode: String?
    func configureRecoveryFailure(_ error: APIError?) { recoveryFailure = error }
    func requestPasswordReset(email: String) throws {
        recoveryRequests += 1
        if let recoveryFailure { throw recoveryFailure }
    }
    func resetPassword(email: String, resetCode: String, newPassword: String) throws {
        passwordResets += 1
        if let recoveryFailure { throw recoveryFailure }
        resetEmail = email; submittedResetCode = resetCode
    }
    func profile() throws -> ProfileRecord {
        if let profileRefreshError { throw profileRefreshError }
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
    func uploadPhoto(_ data: Data, contentType: String) throws { if failWrites { throw APIError.http(503, "Unavailable") }; photoWrites += 1 }
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

@Test @MainActor func questionnaireSelectionWaitsForContinueAndResetsOnlyNewQuestions() async throws {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let flow = AttributeQuestionnaire()
    flow.load(session.currentUser.attributes)
    #expect(flow.selectedOption == nil && flow.importance == 3)
    #expect(try await !flow.saveAnswer(in: session))
    flow.selectedOption = "Atheist"
    flow.importance = 5
    #expect(await repository.savedAttributes.isEmpty)
    #expect(flow.index == 0)
    #expect(try await flow.saveAnswer(in: session))
    #expect(session.currentUser.attributes.first?.value == "Atheist")
    #expect(session.currentUser.attributes.first?.importance == 5)
    #expect(!flow.advance())
    #expect(flow.selectedOption == nil && flow.importance == 3)
    flow.selectedOption = "Want"
    flow.importance = 1
    flow.back()
    #expect(flow.selectedOption == "Atheist" && flow.importance == 5)
    #expect(!flow.advance())
    #expect(flow.selectedOption == "Want" && flow.importance == 1)
    #expect(try await flow.saveAnswer(in: session))
    #expect(session.currentUser.attributes.count == 2)
}

@Test @MainActor func questionnaireSaveFailureKeepsSelectionAndCanRetryBeforeFinishing() async throws {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let flow = AttributeQuestionnaire()
    flow.load([])
    flow.selectedOption = "Spiritual"
    flow.importance = 4
    await repository.configure(fail: true)
    await #expect(throws: APIError.http(503, "Unavailable")) {
        _ = try await flow.saveAnswer(in: session)
    }
    #expect(flow.index == 0 && flow.selectedOption == "Spiritual" && flow.importance == 4)
    #expect(!flow.saving && session.currentUser.attributes.isEmpty)
    await repository.configure()
    #expect(try await flow.saveAnswer(in: session))
    for _ in 0..<(flow.questions.count - 1) { #expect(!flow.advance()) }
    #expect(flow.isLastQuestion && flow.importance == 3 && flow.selectedOption == nil)
    #expect(flow.advance())
    #expect(session.currentUser.attributes.count == 1)
}

@Test @MainActor func questionnaireLoadsSavedAnswersAndSkipPreservesServerValues() async throws {
    let repository = AdapterRepository()
    let saved = Attribute(name: "children", importance: 2, value: "Not sure yet")
    _ = try await repository.saveAttributes([AttributeRecord(name: saved.name, importance: saved.importance, value: saved.value)])
    let session = SessionStore(repository: repository)
    await session.restore()
    let flow = AttributeQuestionnaire()
    flow.load(session.currentUser.attributes)
    #expect(!flow.advance())
    #expect(flow.selectedOption == saved.value && flow.importance == saved.importance)
    flow.selectedOption = "Want"
    flow.importance = 5
    flow.load(session.currentUser.attributes)
    #expect(flow.selectedOption == "Want" && flow.importance == 5)
    #expect(!flow.advance()) // Skip doesn't persist the changed draft.
    #expect(session.currentUser.attributes.first?.value == saved.value)
    #expect(session.currentUser.attributes.first?.importance == saved.importance)
    #expect(flow.importance == 3)
    flow.back()
    #expect(flow.selectedOption == "Want" && flow.importance == 5)
}

@Test @MainActor func attributesOverviewCountsKnownAnswersAndIdentifiesMissingTopics() {
    let summary = PersonalAttributesSummary(attributes: [
        Attribute(name: "religion", importance: 4, value: "Spiritual"),
        Attribute(name: "children", importance: 2, value: "Not sure yet"),
        Attribute(name: "religion", importance: 3, value: "Other"),
        Attribute(name: "diet", importance: 3, value: "  "),
        Attribute(name: "legacy", importance: 5, value: "Synthetic legacy value")
    ])
    #expect(summary.hasSavedAnswers && summary.answeredCount == 2)
    #expect(summary.answer(for: "religion")?.value == "Spiritual")
    #expect(summary.answer(for: "diet") == nil)
    #expect(summary.answer(for: "exercise") == nil)
    #expect(!PersonalAttributesSummary(attributes: []).hasSavedAnswers)
    #expect(!PersonalAttributesSummary(attributes: [Attribute(name: "legacy", importance: 3, value: "Other")]).hasSavedAnswers)
}

@Test @MainActor func directAttributeEditSavesOnlySelectedTopicAndCanCancelOrRetry() async throws {
    let repository = AdapterRepository()
    _ = try await repository.saveAttributes([
        AttributeRecord(name: "religion", importance: 4, value: "Spiritual"),
        AttributeRecord(name: "diet", importance: 2, value: "Vegetarian")
    ])
    let session = SessionStore(repository: repository)
    await session.restore()
    let flow = AttributeQuestionnaire(category: "children")
    flow.load(session.currentUser.attributes)
    #expect(flow.isSingleQuestion && flow.question.category == "children")
    #expect(flow.selectedOption == nil && flow.importance == 3)
    flow.selectedOption = "Want"
    #expect(try await flow.saveAnswer(in: session))
    #expect(flow.advance() && flow.question.category == "children")
    let summary = PersonalAttributesSummary(attributes: session.currentUser.attributes)
    #expect(summary.answeredCount == 3)
    #expect(summary.answer(for: "children")?.value == "Want")
    #expect(summary.answer(for: "religion")?.importance == 4)
    #expect(summary.answer(for: "diet")?.value == "Vegetarian")

    let discarded = AttributeQuestionnaire(category: "children")
    discarded.load(session.currentUser.attributes)
    discarded.selectedOption = "Don't want"
    discarded.importance = 1 // Cancel discards this draft without calling saveAnswer.
    let reopened = AttributeQuestionnaire(category: "children")
    reopened.load(session.currentUser.attributes)
    #expect(reopened.selectedOption == "Want" && reopened.importance == 3)
    reopened.selectedOption = "Don't want"
    reopened.importance = 1
    await repository.configure(fail: true)
    await #expect(throws: APIError.http(503, "Unavailable")) { _ = try await reopened.saveAnswer(in: session) }
    #expect(reopened.question.category == "children" && !reopened.saving)
    #expect(PersonalAttributesSummary(attributes: session.currentUser.attributes).answer(for: "children")?.value == "Want")
    await repository.configure()
    #expect(try await reopened.saveAnswer(in: session))
    try await session.reloadProfile()
    let updated = PersonalAttributesSummary(attributes: session.currentUser.attributes)
    #expect(updated.answeredCount == 3)
    #expect(updated.answer(for: "children")?.value == "Don't want")
    #expect(updated.answer(for: "children")?.importance == 1)
    #expect(updated.answer(for: "religion")?.value == "Spiritual")
}


@Test @MainActor func onboardingDraftSurvivesNewSessionAndVerificationWithoutLosingPhotoOrStep() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    let id = UUID()
    await repository.configure(missing: true)
    await repository.configureAccount(id: id, confirmed: false)
    let first = SessionStore(repository: repository, draftStore: store)
    await first.restore()
    #expect(first.showVerification && first.currentUser.id == id)
    first.showVerification = false
    first.draft.firstName = "Taylor"
    first.draft.lastName = "Example"
    first.draft.birthdate = try WireDates.birthday("2000-02-29")
    first.draft.graduationYear = "2028"
    first.draft.major = "Computing"
    first.draft.step = 2
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
        UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
    let photo = try #require(image.jpegData(compressionQuality: 0.8))
    first.draft.photo = photo
    let expected = first.draft
    await repository.configureAccount(id: id, confirmed: true)
    let relaunched = SessionStore(repository: repository, draftStore: store)
    await relaunched.restore()
    #expect(relaunched.authenticated && relaunched.needsProfile && !relaunched.showVerification)
    #expect(relaunched.draft == expected)
    try await relaunched.refreshAccount()
    #expect(relaunched.draft == expected)
    #expect(relaunched.accountInfo?.emailConfirmed == true)
    try await relaunched.finishOnboarding()
    #expect(!relaunched.needsProfile && relaunched.currentUser.firstName == "Taylor")
    #expect(await repository.photoWrites == 1)
    #expect(try store.load(accountID: id) == nil)
}

@Test @MainActor func onboardingDraftsAreIsolatedAcrossAccountsAndSurviveSignOut() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    await repository.configure(missing: true)
    let firstID = UUID(), secondID = UUID()
    await repository.configureAccount(id: firstID, confirmed: false)
    let session = SessionStore(repository: repository, draftStore: store)
    try await session.signIn(email: "alex@example.test", password: "Synthetic123!")
    session.draft.firstName = "Taylor"
    session.draft.step = 1
    try await session.signOut()
    #expect(session.draft.firstName.isEmpty && session.accountInfo == nil)
    await repository.configureAccount(id: secondID, confirmed: false)
    try await session.signIn(email: "jordan@example.test", password: "Synthetic123!")
    #expect(session.draft.firstName.isEmpty && session.draft.step == 0)
    session.draft.firstName = "Jordan"
    try await session.signOut()
    await repository.configureAccount(id: firstID, confirmed: true)
    try await session.signIn(email: "alex@example.test", password: "Synthetic123!")
    #expect(session.draft.firstName == "Taylor" && session.draft.step == 1)
    try await session.deleteAccount()
    #expect(try store.load(accountID: firstID) == nil)
    #expect(try store.load(accountID: secondID)?.firstName == "Jordan")
}

@Test @MainActor func failedOnboardingWriteRetainsPersistedDraftForRetry() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    await repository.configure(missing: true, fail: true)
    let session = SessionStore(repository: repository, draftStore: store)
    await session.restore()
    session.draft.firstName = "Taylor"
    session.draft.birthdate = try WireDates.birthday("2000-02-29")
    session.draft.step = 2
    let id = try #require(session.accountInfo?.id)
    await #expect(throws: APIError.http(503, "Unavailable")) { try await session.finishOnboarding() }
    #expect(session.needsProfile && session.draft.firstName == "Taylor" && session.draft.step == 2)
    #expect(try store.load(accountID: id) == session.draft)
    await repository.configure(missing: true)
    try await session.finishOnboarding()
    #expect(!session.needsProfile && session.currentUser.firstName == "Taylor")
}

@Test @MainActor func draftStorageFailureIsVisibleAndRetrySavesLatestChanges() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    await repository.configure(missing: true)
    let session = SessionStore(repository: repository, draftStore: store)
    await session.restore()
    try Data().write(to: directory)
    session.draft.firstName = "Taylor"
    #expect(session.draftSaveError != nil)
    try FileManager.default.removeItem(at: directory)
    session.persistDraft()
    #expect(session.draftSaveError == nil)
    #expect(try store.load(accountID: #require(session.accountInfo?.id))?.firstName == "Taylor")
}


@Test @MainActor func failedOnboardingPhotoDoesNotCreateProfileOrDiscardDraft() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    await repository.configure(missing: true, fail: true)
    let session = SessionStore(repository: repository, draftStore: store)
    await session.restore()
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in }
    let photo = try #require(image.jpegData(compressionQuality: 0.8))
    session.draft.photo = photo
    session.draft.firstName = "Taylor"
    session.draft.step = 2
    await #expect(throws: APIError.http(503, "Unavailable")) { try await session.finishOnboarding() }
    #expect(session.needsProfile && session.draft.photo != nil)
    #expect(await repository.savedFields == nil)
    #expect(try store.load(accountID: #require(session.accountInfo?.id))?.photo == session.draft.photo)
}

@Test func onboardingValidationMatchesRequiredProfileFields() {
    var draft = OnboardingDraft()
    #expect(draft.validationMessage(for: 0) != nil)
    draft.firstName = "Taylor"; draft.lastName = "Example"
    #expect(draft.validationMessage(for: 0) == nil)
    #expect(draft.validationMessage(for: 1) != nil)
    draft.major = "Computing"; draft.graduationYear = "2028"
    #expect(draft.validationMessage(for: 1) == nil)
    draft.graduationYear = "20"
    #expect(draft.validationMessage(for: 1) != nil)
    draft.graduationYear = "2201"
    #expect(draft.validationMessage(for: 1) != nil)
    #expect(draft.validationMessage(for: 2) == nil)
}

@Test @MainActor func onboardingPhotoPickerCommitsOnlyConfirmedCropAndPreservesDraftOnCancelOrFailure() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = OnboardingDraftStore(directory: directory)
    let repository = AdapterRepository()
    await repository.configure(missing: true)
    let session = SessionStore(repository: repository, draftStore: store)
    await session.restore()
    let id = try #require(session.accountInfo?.id)
    let format = UIGraphicsImageRendererFormat(); format.scale = 1
    let original = UIGraphicsImageRenderer(size: CGSize(width: 2400, height: 1200), format: format).image { context in
        UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2400, height: 1200))
    }
    let cropped = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 2000), format: format).image { context in
        UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2000, height: 2000))
    }
    session.draft.photo = try OnboardingPhotoPicker.jpegData(for: original)
    let previous = session.draft.photo
    var presented = true
    var results = 0
    var failed = false
    let picker = OnboardingPhotoPicker(isPresented: .init(get: { presented }, set: { presented = $0 })) { result in
        results += 1
        switch result {
        case .success(let data): session.draft.photo = data
        case .failure: failed = true
        }
    }
    let coordinator = picker.makeCoordinator()
    let controller = UIImagePickerController()
    coordinator.imagePickerControllerDidCancel(controller)
    #expect(!presented && results == 0 && session.draft.photo == previous)
    #expect(try store.load(accountID: id)?.photo == previous)

    presented = true
    coordinator.imagePickerController(controller, didFinishPickingMediaWithInfo: [.originalImage: original, .editedImage: cropped])
    let confirmed = try #require(session.draft.photo)
    let decoded = try #require(UIImage(data: confirmed))
    #expect(!presented && results == 1 && !failed)
    #expect(decoded.size == CGSize(width: 1600, height: 1600))
    #expect(confirmed == (try OnboardingPhotoPicker.jpegData(for: cropped)))
    #expect(try store.load(accountID: id)?.photo == confirmed)
    #expect(await repository.photoWrites == 0)

    presented = true
    coordinator.imagePickerController(controller, didFinishPickingMediaWithInfo: [.originalImage: original])
    #expect(!presented && results == 2 && failed)
    #expect(session.draft.photo == confirmed)
    #expect(try store.load(accountID: id)?.photo == confirmed)
}


@Test @MainActor func matchRefreshIgnoresCancellationAndLoadsAgainOnNextActivation() async throws {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let user = session.currentUser
    let state = MatchRefreshState()
    for duringProfile in [false, true] {
        for error: any Error & Sendable in [CancellationError(), URLError(.cancelled)] {
            await repository.configureRefreshError(error, duringProfile: duringProfile)
            await state.load(session: session)
            #expect(state.errorMessage == nil && state.loading)
            #expect(session.authenticated && session.currentUser === user)
        }
    }
    await repository.configureRefreshError(nil)
    await state.load(session: session)
    #expect(!state.loading && state.errorMessage == nil)
    #expect(session.currentUser.matches.count == 1)
    let refreshedUser = session.currentUser
    await repository.configureRefreshError(URLError(.cancelled), duringProfile: true)
    await state.load(session: session)
    #expect(!state.loading && state.errorMessage == nil)
    #expect(session.currentUser === refreshedUser)
}

@Test @MainActor func matchRefreshStillReportsRealErrorsAndClearsThemAfterRecovery() async {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let state = MatchRefreshState()
    await repository.configureRefreshError(URLError(.notConnectedToInternet))
    await state.load(session: session)
    #expect(!state.loading && state.errorMessage != nil)
    await repository.configureRefreshError(APIError.http(503, "Unavailable"), duringProfile: true)
    await state.load(session: session)
    #expect(state.errorMessage == "Unavailable")
    await repository.configureRefreshError(nil)
    await state.load(session: session)
    #expect(state.errorMessage == nil && !state.loading)
}

@Test @MainActor func alreadyCancelledMatchRefreshDoesNotChangeDisplayedState() async {
    let repository = AdapterRepository()
    let session = SessionStore(repository: repository)
    await session.restore()
    let user = session.currentUser
    let state = MatchRefreshState(loading: false)
    await Task {
        withUnsafeCurrentTask { $0?.cancel() }
        await state.load(session: session)
    }.value
    #expect(state.errorMessage == nil && !state.loading)
    #expect(session.currentUser === user)
}

@Test @MainActor func recoveryRetainsFailedResetForRetryAndClearsSecretsOnlyOnSuccess() async {
    let repository = AdapterRepository()
    let state = PasswordRecoveryState(email: " alex@example.test \n")
    await repository.configureRecoveryFailure(.http(503, "Mail unavailable"))
    await state.requestCode(repository: repository)
    #expect(state.stage == .request && state.errorMessage != nil && !state.busy)
    await repository.configureRecoveryFailure(nil)
    await state.requestCode(repository: repository)
    #expect(state.stage == .reset && state.email == "alex@example.test")
    #expect(state.errorMessage == nil && !state.busy)
    state.resetCode = " synthetic-code_- \n"; state.newPassword = "Replacement456!"
    await repository.configureRecoveryFailure(.http(400, "Invalid token."))
    await state.reset(repository: repository)
    #expect(state.stage == .reset && state.errorMessage?.contains("expired") == true)
    #expect(!state.resetCode.isEmpty && !state.newPassword.isEmpty)
    await repository.configureRecoveryFailure(nil)
    // The reset uses the address the code was requested for, even if UI state changes.
    state.email = "different@example.test"
    await state.reset(repository: repository)
    #expect(state.stage == .complete && state.resetCode.isEmpty && state.newPassword.isEmpty)
    #expect(await repository.resetEmail == "alex@example.test")
    #expect(await repository.submittedResetCode == "synthetic-code_-")
}

@Test @MainActor func recoveryValidatesInputSuppressesDuplicateRequestsAndSupportsChangingAddress() async {
    let repository = AdapterRepository()
    let state = PasswordRecoveryState()
    await state.requestCode(repository: repository)
    #expect(state.stage == .request && state.errorMessage != nil)
    #expect(await repository.recoveryRequests == 0)
    state.email = "alex@example.test"
    let first = Task { await state.requestCode(repository: repository) }
    let second = Task { await state.requestCode(repository: repository) }
    await first.value; await second.value
    #expect(await repository.recoveryRequests == 1)
    await state.reset(repository: repository)
    #expect(await repository.passwordResets == 0)
    state.resetCode = "synthetic"; state.newPassword = "weak"
    await state.reset(repository: repository)
    #expect(await repository.passwordResets == 0)
    state.changeEmail()
    #expect(state.stage == .request && state.resetCode.isEmpty && state.newPassword.isEmpty)
    #expect(state.errorMessage == nil)
    // Editing an address must not bypass the resend cooldown.
    state.email = "different@example.test"
    await state.requestCode(repository: repository)
    #expect(await repository.recoveryRequests == 1)
}

@Test @MainActor func recoveryCanUseAnExistingCodeAfterReopeningAppWithoutSendingAnotherEmail() async {
    let repository = AdapterRepository()
    let state = PasswordRecoveryState(email: "alex@example.test")
    state.useExistingCode()
    #expect(state.stage == .reset && !state.codeRequested)
    #expect(await repository.recoveryRequests == 0)
    state.resetCode = "synthetic-code_-"; state.newPassword = "Replacement456!"
    await state.reset(repository: repository)
    #expect(state.stage == .complete && state.resetCode.isEmpty && state.newPassword.isEmpty)
    #expect(await repository.passwordResets == 1)
}

@Test @MainActor func nativePasswordFieldKeepsTextAndSelectionAcrossShowHideAndConfiguresAutoFill() throws {
    var password = "Synthetic123!"
    var focused = false
    var submitted = false
    var input = PasswordTextField(text: .init(get: { password }, set: { password = $0 }),
                                  focused: .init(get: { focused }, set: { focused = $0 }),
                                  revealed: false, isNewPassword: false, placeholder: "Password", onSubmit: { submitted = true })
    let field = UITextField()
    input.updateField(field)
    #expect(field.isSecureTextEntry && field.textContentType == .password && field.text == password)
    let position = try #require(field.position(from: field.beginningOfDocument, offset: 3))
    field.selectedTextRange = field.textRange(from: position, to: position)
    input.revealed = true
    input.updateField(field)
    #expect(!field.isSecureTextEntry && field.text == password)
    let selection = try #require(field.selectedTextRange)
    #expect(field.offset(from: field.beginningOfDocument, to: selection.start) == 3)
    input.revealed = false
    input.isNewPassword = true
    input.updateField(field)
    #expect(field.isSecureTextEntry && field.text == password && field.textContentType == .newPassword)
    #expect(field.passwordRules != nil)
    let coordinator = input.makeCoordinator()
    field.text = "GeneratedPassword456!"
    coordinator.changed(field)
    #expect(password == "GeneratedPassword456!")
    #expect(!coordinator.textFieldShouldReturn(field) && submitted)
}

@Test func passwordRequirementsMatchIdentityRulesAndIdentifiersPreserveAutoFilledEmails() {
    #expect(PasswordPolicy.accepts("Aa1234567!"))
    for password in ["Aa123456!", "aaaaaaaaa!", "AAAAAAAA1!", "Abcdefghi!", "Abcdefghi1", "Ää1234567!"] {
        #expect(!PasswordPolicy.accepts(password))
    }
    #expect(AuthIdentifier.email(" alex@example.test \n") == "alex@example.test")
    #expect(AuthIdentifier.email("   ").isEmpty)
}
