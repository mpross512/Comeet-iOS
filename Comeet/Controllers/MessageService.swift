import Foundation
import ComeetData

@MainActor
final class MessageService {
    private let repository: any ComeetRepository
    init(repository: any ComeetRepository = APIConfiguration.client) { self.repository = repository }
    func addMessage(conversationID: Int, messageID: Int, response: String, clientID: UUID = UUID()) async throws {
        _ = try await repository.sendMessage(conversationID: conversationID, replyToID: messageID > 0 ? messageID : nil, text: response, clientID: clientID)
    }
}
