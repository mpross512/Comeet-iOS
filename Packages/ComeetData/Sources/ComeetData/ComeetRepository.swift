import Foundation

public protocol ComeetRepository: Sendable {
    func restoreSession() async throws -> Bool
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func account() async throws -> AccountInfo
    func resendConfirmation(email: String) async throws
    func profile() async throws -> ProfileRecord
    func saveProfile(_ fields: ProfileFields) async throws -> ProfileRecord
    func saveAttributes(_ attributes: [AttributeRecord]) async throws -> [AttributeRecord]
    func like(matchID: UUID) async throws -> LikeRecord
    func conversations() async throws -> [ConversationRecord]
    func messages(conversationID: Int, afterID: Int) async throws -> [MessageRecord]
    func sendMessage(conversationID: Int, replyToID: Int?, text: String, clientID: UUID) async throws -> MessageRecord
    func uploadPhoto(_ data: Data, contentType: String) async throws
    func deleteAccount() async throws
}
