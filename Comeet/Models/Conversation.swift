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
    /// Loads the conversation list. Conversations already on screen are reused and only fetch newer
    /// messages, so an open chat keeps the same object while the list refreshes underneath it.
    @MainActor
    static func all(repository: any ComeetRepository = APIConfiguration.client,
                    reusing existing: [Conversation] = []) async throws -> [Conversation] {
        let known = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var conversations: [Conversation] = []
        for record in try await repository.conversations() {
            if let conversation = known[record.id] {
                try await conversation.refresh(repository: repository)
                conversations.append(conversation)
            } else {
                let conversation = Conversation(record: record)
                // Drain the paginated history so the screen has all prior messages.
                conversation.messages = []
                try await conversation.refresh(repository: repository)
                conversations.append(conversation)
            }
        }
        return conversations
    }
    // Polling lives in the chat view's structured task, so leaving the chat cancels it.
    @MainActor
    func refresh(repository: any ComeetRepository = APIConfiguration.client) async throws {
        var cursor = messages.last?.id ?? 0
        while true {
            let page = try await repository.messages(conversationID: id, afterID: cursor)
            insert(page)
            guard page.count == 100, let next = page.last?.id else { return }
            cursor = next
        }
    }
    /// Adds messages not already present, keeping server ID order. Used for poll pages and for the
    /// message a successful send returns, so the reply appears without waiting for the next poll.
    @MainActor
    func insert(_ records: [MessageRecord]) {
        var seen = Set(messages.map(\.id))
        let new = records.filter { seen.insert($0.id).inserted }
        guard !new.isEmpty else { return }
        messages.append(contentsOf: new)
        messages.sort { $0.id < $1.id }
    }
    /// Message IDs increase with time on the server, so the latest ID orders conversations by activity.
    var lastActivityID: Int { messages.last?.id ?? 0 }
    /// The latest message when it still offers responses, i.e. the prompt the current user can answer.
    var openPrompt: MessageRecord? {
        guard let last = messages.last, !last.responseOptions.isEmpty else { return nil }
        return last
    }
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Converts stored message text into what people read. Message text is user data, so callers must
/// render the result verbatim rather than as a localization key or Markdown.
enum MessageText {
    static let dateSlotsOption = "{datetime_3}"
    static let slotSeparator: Character = "|"

    static func isSystem(_ message: MessageRecord) -> Bool { message.sender == Constants.Values.comeetUID }

    /// The reply text for three proposed date times: ISO 8601 instants joined by `|`.
    static func encodeDateSlots(_ dates: [Date]) -> String {
        dates.map { $0.formatted(.iso8601) }.joined(separator: String(slotSeparator))
    }

    /// Parses a proposed-times reply. Also accepts the `Date.description` format older builds sent.
    static func dateSlots(in text: String) -> [Date]? {
        let parts = text.split(separator: slotSeparator, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else { return nil }
        let legacy = DateFormatter()
        legacy.locale = Locale(identifier: "en_US_POSIX")
        legacy.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let dates = parts.compactMap { part in (try? Date(part, strategy: .iso8601)) ?? legacy.date(from: part) }
        return dates.count == 3 ? dates : nil
    }

    static func optionLabel(_ option: String) -> String {
        option == dateSlotsOption ? "Suggest 3 Times" : option
    }

    /// Full text for a chat bubble.
    static func body(of message: MessageRecord, peer: ConversationPeer) -> String {
        if let dates = dateSlots(in: message.text) {
            let lines = dates.map { "• " + $0.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()) }
            return (["Suggested times:"] + lines).joined(separator: "\n")
        }
        return message.text.replacingOccurrences(of: "{user}", with: peer.firstName)
    }

    /// One-line summary for the chat list, saying who sent the latest message.
    static func preview(of message: MessageRecord?, peer: ConversationPeer, currentUserID: UUID) -> String {
        guard let message else { return "No messages yet" }
        let text = dateSlots(in: message.text) != nil ? "Suggested 3 times to meet" : body(of: message, peer: peer)
        return message.sender == currentUserID ? "You: \(text)" : text
    }
}
