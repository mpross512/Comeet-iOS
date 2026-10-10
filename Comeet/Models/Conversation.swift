import Foundation
import Observation
import ComeetData

@Observable
final class Conversation: Identifiable, Hashable {
    var id: Int
    var recipientID: UUID = UUID()
    var messages: [Message] = []
    init() { id = 0 }
    init(record: ConversationRecord, userID: UUID) {
        id = record.id
        recipientID = record.members.first { $0.id != userID }?.id ?? userID
        messages = record.messages.map(Message.init(record:))
    }
    @MainActor
    static func all(userID: UUID, repository: any ComeetRepository = APIConfiguration.client) async throws -> [Conversation] {
        let conversations = try await repository.conversations().map { Conversation(record: $0, userID: userID) }
        for conversation in conversations {
            // Drain the paginated history so the existing screen still has all prior messages.
            conversation.messages = []
            try await conversation.refresh(repository: repository)
        }
        return conversations
    }
    // Polling lives in the view's structured task, so leaving chat cancels it.
    @MainActor
    func refresh(repository: any ComeetRepository = APIConfiguration.client) async throws {
        var cursor = messages.last?.id ?? 0
        while true {
            let page = try await repository.messages(conversationID: id, afterID: cursor)
            let existing = Set(messages.map(\.id))
            messages.append(contentsOf: page.filter { !existing.contains($0.id) }.map(Message.init(record:)))
            messages.sort { $0.id < $1.id }
            guard page.count == 100, let next = page.last?.id else { return }
            cursor = next
        }
    }
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
