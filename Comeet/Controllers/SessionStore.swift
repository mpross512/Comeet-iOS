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
    var currentUser = User()
    var authenticated = false
    var restored = false
    var needsProfile = false
    var errorMessage: String?
    private(set) var profilePhotoRevision = UUID()

    init(repository: any ComeetRepository = APIConfiguration.client,
         photoCache: ProfilePhotoCache = ProfilePhotoCache()) {
        self.repository = repository
        self.photoCache = photoCache
    }

    func restore() async {
        errorMessage = nil
        do {
            authenticated = try await repository.restoreSession()
            if authenticated { try await reloadProfile() }
            restored = true
        } catch { errorMessage = error.localizedDescription }
    }
    func signIn(email: String, password: String) async throws {
        try await repository.signIn(email: email, password: password)
        try await reloadProfile()
        authenticated = true
    }
    func signUp(email: String, password: String) async throws {
        try await repository.signUp(email: email, password: password)
        try await reloadProfile()
        authenticated = true
    }
    func signOut() async throws {
        defer { clearUser() }
        try await repository.signOut()
    }
    func deleteAccount() async throws {
        try await repository.deleteAccount()
        clearUser()
    }
    func reloadProfile() async throws {
        do {
            currentUser = try User(record: await repository.profile())
            needsProfile = false
        } catch APIError.http(404, _) {
            currentUser = User()
            needsProfile = true
        } catch APIError.signedOut {
            clearUser()
            throw APIError.signedOut
        }
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
