import Foundation

public struct AccountInfo: Codable, Sendable {
    public let id: UUID
    public let email: String
    public let emailConfirmed: Bool
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
    public let likedUserIds: [UUID]
}

public struct LikeRecord: Decodable, Sendable {
    public let conversationId: Int?
}

public struct ConversationPeer: Decodable, Sendable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public var fullName: String { "\(firstName) \(lastName)" }
}

public struct ConversationRecord: Decodable, Sendable {
    public let id: Int
    public let peer: ConversationPeer
    public let messages: [MessageRecord]
}

public struct MessageRecord: Decodable, Sendable, Identifiable {
    public let id: Int
    public let conversationId: Int
    public let sender: UUID
    public let text: String
    public let createdAtUnixMilliseconds: Int64
    public let responseOptions: [String]
    public var timestamp: Date { Date(timeIntervalSince1970: Double(createdAtUnixMilliseconds) / 1000) }
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
}
