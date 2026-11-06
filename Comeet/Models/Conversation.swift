import Foundation
import Observation
import ComeetData

@Observable
final class Conversation: Identifiable, Hashable {
    let id: Int
    let peer: ConversationPeer
    var messages: [MessageRecord]
    init(record: ConversationRecord) {
        id = record.id
        peer = record.peer
        messages = record.messages
    }
    @MainActor
    static func all(repository: any ComeetRepository = APIConfiguration.client) async throws -> [Conversation] {
        let conversations = try await repository.conversations().map(Conversation.init(record:))
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
            messages.append(contentsOf: page.filter { !existing.contains($0.id) })
            messages.sort { $0.id < $1.id }
            guard page.count == 100, let next = page.last?.id else { return }
            cursor = next
        }
    }
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
