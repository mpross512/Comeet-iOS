import Foundation
import Observation
import ComeetData

// Observable UI state stays on the main actor; the repository owns transport and secure tokens.
@MainActor @Observable
final class SessionStore {
    static let shared = SessionStore()
    let repository: any ComeetRepository
    var currentUser = User()
    var authenticated = false
    var restored = false
    var needsProfile = false
    var errorMessage: String?

    init(repository: any ComeetRepository = APIConfiguration.client) { self.repository = repository }

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
    func handle(_ error: Error) {
        if error as? APIError == .signedOut { clearUser() }
    }
    private func clearUser() {
        currentUser = User(); authenticated = false; needsProfile = false
    }
}

@MainActor
final class APIConfiguration {
    static let baseURL: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ComeetAPIBaseURL") as? String,
              let url = URL(string: value), let host = url.host,
              url.scheme == "https" || (url.scheme == "http" && ["localhost", "127.0.0.1"].contains(host)) else {
            preconditionFailure("Set ComeetAPIBaseURL to an HTTPS API address (or loopback HTTP for development).")
        }
        return url
    }()
    static let client = APIClient(baseURL: baseURL)
    static func photoURL(userID: UUID) -> URL { client.photoURL(userID: userID) }
}
