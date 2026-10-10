import Foundation
import Observation
import ComeetData

@MainActor @Observable
final class UserService {
    private let repository: any ComeetRepository
    var errorMessage: String?
    init(repository: any ComeetRepository = APIConfiguration.client) { self.repository = repository }

    func likeUser(userID: UUID, matchID: UUID) async -> Bool {
        do {
            _ = try await repository.like(matchID: matchID)
            return true
        } catch {
            SessionStore.shared.handle(error)
            errorMessage = error.localizedDescription
            return false
        }
    }
    func uploadNewImage(data: Data) async throws {
        try await repository.uploadPhoto(data, contentType: "image/jpeg")
    }
    func saveAttributes(_ attributes: [Attribute]) async throws {
        _ = try await repository.saveAttributes(attributes.map { AttributeRecord(name: $0.name, importance: $0.importance, value: $0.value) })
    }
}
