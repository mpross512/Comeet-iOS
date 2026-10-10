import Foundation

public struct AccountInfo: Codable, Sendable {
    public let id: UUID
    public let email: String
    public let emailConfirmed: Bool
    enum CodingKeys: String, CodingKey { case id, email; case emailConfirmed = "email_confirmed" }
}

public struct ProfileFields: Codable, Sendable {
    public var firstName: String
    public var lastName: String
    public var birthdate: String
    public var graduationYear: Int
    public var major: String
    public var bio: String
    public init(firstName: String, lastName: String, birthdate: String, graduationYear: Int, major: String, bio: String) {
        self.firstName = firstName; self.lastName = lastName; self.birthdate = birthdate
        self.graduationYear = graduationYear; self.major = major; self.bio = bio
    }
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name", lastName = "last_name", graduationYear = "graduation_year"
        case birthdate, major, bio
    }
}

public struct AttributeRecord: Codable, Sendable, Equatable {
    public let name: String
    public let importance: Int
    public let value: String
    public init(name: String, importance: Int, value: String) {
        self.name = name; self.importance = importance; self.value = value
    }
}

public struct PersonRecord: Decodable, Sendable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let birthdate: String
    public let graduationYear: Int
    public let major: String
    public let bio: String
    public let attributes: [AttributeRecord]
    enum CodingKeys: String, CodingKey {
        case id, birthdate, major, bio, attributes
        case firstName = "first_name", lastName = "last_name", graduationYear = "graduation_year"
    }
}

public struct ProfileRecord: Decodable, Sendable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let birthdate: String
    public let graduationYear: Int
    public let major: String
    public let bio: String
    public let matches: [PersonRecord]
    public let attributes: [AttributeRecord]
    public let likes: [UserIDRecord]
    public let conversations: [ConversationIDRecord]
    enum CodingKeys: String, CodingKey {
        case id, birthdate, major, bio, conversations
        case firstName = "first_name", lastName = "last_name", graduationYear = "graduation_year"
        case matches = "user_matches", attributes = "v_user_attributes", likes = "user_likes"
    }
}

public struct UserIDRecord: Decodable, Sendable { public let id: UUID }
public struct ConversationIDRecord: Decodable, Sendable { public let id: Int }
public struct LikeRecord: Decodable, Sendable {
    public let conversationID: Int?
    enum CodingKeys: String, CodingKey { case conversationID = "conversation_id" }
}
public struct MemberRecord: Decodable, Sendable {
    public let id: UUID
    enum CodingKeys: String, CodingKey { case id = "member_id" }
}
public struct ConversationRecord: Decodable, Sendable {
    public let id: Int
    public let members: [MemberRecord]
    public let messages: [MessageRecord]
    enum CodingKeys: String, CodingKey { case id, messages; case members = "conversation_members" }
}
public struct MessageRecord: Codable, Sendable {
    public let id: Int
    public let conversationID: Int
    public let sender: UUID
    public let text: String
    public let timestamp: Date
    public let responseOptions: [String]
    public let isPublic: Bool
    enum CodingKeys: String, CodingKey {
        case id, sender, text
        case conversationID = "conversation_id", timestamp = "created_at", responseOptions = "response_option", isPublic = "public"
    }
}

public enum WireDates {
    // Date-only values represent calendar birthdays, independent of time zone and locale.
    public static func birthday(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
    public static func birthday(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
            throw APIError.invalidResponse
        }
        return date
    }
    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: value) else { throw APIError.invalidResponse }
            return date
        }
        return decoder
    }
}
