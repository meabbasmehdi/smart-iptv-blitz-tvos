import Foundation

struct AuthTokenRequest: Encodable {
    let deviceId: String
    let timestamp: String
    let nonce: String
    let hmacHash: String

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case timestamp
        case nonce
        case hmacHash = "hmac_hash"
    }
}

struct AuthTokenResponse: Decodable {
    let token: String?
    let success: Bool?
    let message: String?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case token
        case success
        case message
        case expiresAt = "expires_at"
    }
}

struct TokenValidationResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct DeviceRegistrationRequest: Encodable {
    let deviceId: String
    let deviceType: String
    let appVersion: String
    let platform: String
    let region: String?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case deviceType = "device_type"
        case appVersion = "app_version"
        case platform
        case region
    }
}

struct DeviceRegistrationResponse: Decodable {
    let success: Bool
    let message: String?
    let deviceId: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case deviceId = "device_id"
    }
}

struct DeviceStatusResponse: Decodable {
    let success: Bool
    let exists: Bool?
    let status: String?
    let message: String?
    let onboardingCompleted: Bool?
    let deviceId: String?

    enum CodingKeys: String, CodingKey {
        case success
        case exists
        case status
        case message
        case onboardingCompleted = "onboarding_completed"
        case deviceId = "device_id"
    }
}

struct AppDisclaimerResponse: Decodable {
    let message: String?
    let version: String?
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case message
        case version
        case title
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try? container.decode(String.self, forKey: .message)
        version = container.decodeStringOrNumber(forKey: .version)
        title = try? container.decode(String.self, forKey: .title)
        description = try? container.decode(String.self, forKey: .description)
    }
}

enum PlaylistSource: String, Decodable {
    case xtream
    case `default`
    case m3uLink = "m3u_link"
    case m3uFile = "m3u_file"
    case demo
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self))?.lowercased()
        switch value {
        case "xtream", "xtreme":
            self = .xtream
        case "default":
            self = .default
        case "m3u_link", "link":
            self = .m3uLink
        case "m3u_file", "file":
            self = .m3uFile
        case "demo":
            self = .demo
        default:
            self = .unknown
        }
    }
}

struct PlaylistResponse: Decodable, Identifiable, Equatable {
    let id: Int64?
    let title: String
    let source: PlaylistSource
    let url: String?
    let username: String?
    let password: String?
    let isActive: Bool
    let isValid: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case source
        case sourceType = "source_type"
        case url
        case username
        case password
        case isActive = "is_active"
        case isValid = "is_valid"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(Int64.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title))?.isEmpty == false
            ? (try container.decode(String.self, forKey: .title))
            : "Untitled"
        source = (try? container.decode(PlaylistSource.self, forKey: .source))
            ?? (try? container.decode(PlaylistSource.self, forKey: .sourceType))
            ?? .unknown
        url = try? container.decode(String.self, forKey: .url)
        username = try? container.decode(String.self, forKey: .username)
        password = try? container.decode(String.self, forKey: .password)
        isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
        createdAt = try? container.decode(String.self, forKey: .createdAt)

        if let boolValue = try? container.decode(Bool.self, forKey: .isValid) {
            isValid = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .isValid) {
            isValid = !["false", "0", "invalid"].contains(stringValue.lowercased())
        } else {
            isValid = true
        }
    }
}

struct PlaylistListResponse: Decodable {
    let success: Bool
    let data: [PlaylistResponse]?
    let message: String?
}

private extension KeyedDecodingContainer {
    func decodeStringOrNumber(forKey key: Key) -> String? {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(doubleValue)
        }
        return nil
    }
}
