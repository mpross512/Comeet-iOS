import Foundation
import Observation
import ComeetData
import UIKit
import SDWebImage

// Observable UI state stays on the main actor; the repository owns transport and secure tokens.
@MainActor @Observable
final class SessionStore {
    static let shared = SessionStore()
    let repository: any ComeetRepository
    private let photoCache: ProfilePhotoCache
    private let draftStore: OnboardingDraftStore
    var accountInfo: AccountInfo?
    var showVerification = false
    var draft = OnboardingDraft() { didSet { persistDraft() } }
    var draftSaveError: String?
    private var loadingDraft = false
    var currentUser = User()
    var authenticated = false
    var restored = false
    var needsProfile = false
    var errorMessage: String?
    private(set) var profilePhotoRevision = UUID()

    init(repository: any ComeetRepository = APIConfiguration.client,
         photoCache: ProfilePhotoCache = ProfilePhotoCache(),
         draftStore: OnboardingDraftStore = OnboardingDraftStore()) {
        self.repository = repository
        self.photoCache = photoCache
        self.draftStore = draftStore
    }

    func restore() async {
        errorMessage = nil
        do {
            authenticated = try await repository.restoreSession()
            if authenticated { try await loadAccount(); try await reloadProfile() }
            restored = true
        } catch { errorMessage = error.localizedDescription }
    }
    func signIn(email: String, password: String) async throws {
        try await repository.signIn(email: email, password: password)
        try await loadAccount()
        try await reloadProfile()
        authenticated = true
    }
    func signUp(email: String, password: String) async throws {
        try await repository.signUp(email: email, password: password)
        try await loadAccount()
        try await reloadProfile()
        authenticated = true
    }
    func signOut() async throws {
        defer { clearUser() }
        try await repository.signOut()
    }
    func deleteAccount() async throws {
        try await repository.deleteAccount()
        defer { clearUser() }
        if let id = accountInfo?.id { try draftStore.remove(accountID: id) }
    }
    func reloadProfile() async throws {
        do {
            currentUser = try User(record: await repository.profile())
            needsProfile = false
        } catch APIError.http(404, _) {
            currentUser = User()
            if let id = accountInfo?.id { currentUser.id = id }
            needsProfile = true
        } catch APIError.signedOut {
            clearUser()
            throw APIError.signedOut
        } catch { throw error }
    }
    private func loadAccount() async throws {
        let account = try await repository.account()
        loadingDraft = true
        defer { loadingDraft = false }
        accountInfo = account
        draft = try draftStore.load(accountID: account.id) ?? OnboardingDraft()
        draftSaveError = nil
        showVerification = !account.emailConfirmed
    }
    func refreshAccount() async throws {
        do {
            accountInfo = try await repository.account()
            if accountInfo?.emailConfirmed == true { showVerification = false }
        } catch { handle(error); throw error }
    }
    func persistDraft() {
        guard !loadingDraft, let id = accountInfo?.id else { return }
        do { try draftStore.save(draft, accountID: id); draftSaveError = nil }
        catch { draftSaveError = "Your progress couldn’t be saved on this device. Please try again before leaving." }
    }
    func finishOnboarding() async throws {
        // Upload first: a failed photo upload must not make a missing profile appear complete.
        if let photo = draft.photo { try await uploadPhoto(photo) }
        try await saveProfile(draft.fields)
        if let id = accountInfo?.id { try draftStore.remove(accountID: id) }
        loadingDraft = true
        draft = OnboardingDraft()
        loadingDraft = false
    }
    func saveProfile(_ fields: ProfileFields) async throws {
        currentUser = try User(record: await repository.saveProfile(fields))
        needsProfile = false
    }
    func uploadPhoto(_ data: Data) async throws {
        guard let image = UIImage(data: data) else { throw APIError.invalidResponse }
        let userID = currentUser.id
        try await repository.uploadPhoto(data, contentType: "image/jpeg")
        await photoCache.replace(image, data: data, at: APIConfiguration.photoURL(userID: userID))
        // Only recreate visible owner images after their replacement cache entry is ready.
        if currentUser.id == userID { profilePhotoRevision = UUID() }
    }
    func saveAttributes(_ attributes: [Attribute]) async throws {
        let saved = try await repository.saveAttributes(attributes.map {
            AttributeRecord(name: $0.name, importance: $0.importance, value: $0.value)
        })
        currentUser.attributes = saved.map { Attribute(name: $0.name, importance: $0.importance, value: $0.value) }
    }
    func handle(_ error: Error) {
        if error as? APIError == .signedOut { clearUser() }
    }
    private func clearUser() {
        profilePhotoRevision = UUID()
        loadingDraft = true
        draft = OnboardingDraft()
        loadingDraft = false
        accountInfo = nil; showVerification = false; draftSaveError = nil
        currentUser = User(); authenticated = false; needsProfile = false
    }
}

// Keeps image-library and HTTP cache maintenance out of the picker and transport layer.
@MainActor
final class ProfilePhotoCache {
    private let imageCache: SDImageCache
    private let httpCache: URLCache

    init(imageCache: SDImageCache = .shared, httpCache: URLCache = .shared) {
        self.imageCache = imageCache
        self.httpCache = httpCache
    }

    func replace(_ image: UIImage, data: Data, at url: URL) async {
        httpCache.removeCachedResponse(for: URLRequest(url: url))
        let key = SDWebImageManager.shared.cacheKey(for: url)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            imageCache.store(image, imageData: data, forKey: key, toDisk: true) {
                continuation.resume()
            }
        }
    }
}

@MainActor
final class APIConfiguration {
    static let baseURL: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ComeetAPIBaseURL") as? String,
              let url = URL(string: value), let host = url.host,
              url.scheme == "https" || (url.scheme == "http" && ["localhost", "127.0.0.1", "192.168.88.5"].contains(host)) else {
            preconditionFailure("Set ComeetAPIBaseURL to an HTTPS API address (or loopback HTTP for development).")
        }
        return url
    }()
    static let client = APIClient(baseURL: baseURL)
    static func photoURL(userID: UUID) -> URL { client.photoURL(userID: userID) }
}
