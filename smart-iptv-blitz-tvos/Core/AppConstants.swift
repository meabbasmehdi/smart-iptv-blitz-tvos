import Foundation

enum AppRoute: Equatable {
    case disclaimer
    case playlists
    case createPlaylist
    case home
    case liveTV
    case player
}

enum StartupTarget {
    case onboarding
    case home
}

enum StartupDecision {
    case success(StartupTarget, message: String? = nil)
    case failure(message: String, fallback: StartupTarget)
}

enum PreferenceKeys {
    static let disclaimerAccepted = "pref_disclaimer_accepted"
    static let disclaimerVersion = "pref_disclaimer_version"
    static let playlistOnboardingComplete = "pref_playlist_onboarding_complete"
    static let activePlaylistID = "pref_active_playlist_id"
    static let activePlaylistSource = "pref_active_playlist_source"
    static let activePlaylistTitle = "pref_active_playlist_title"
    static let activePlaylistURL = "pref_active_playlist_url"
    static let activePlaylistUsername = "pref_active_playlist_username"
    static let activePlaylistPassword = "pref_active_playlist_password"
    static let stableDeviceSeed = "pref_stable_device_seed"
}

enum AppConstants {
    static let baseURL = URL(string: "https://parser.invotyx.com/")!
    static let tokenRefreshFallbackSeconds: TimeInterval = 24 * 60 * 60

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    static var hmacSecret: String {
        let envValue = ProcessInfo.processInfo.environment["HMAC_SECRET"]
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "HMAC_SECRET") as? String
        let configValue = bundledConfig["HMAC_SECRET"] as? String

        return usableSecret(envValue)
            ?? usableSecret(infoValue)
            ?? usableSecret(configValue)
            ?? ""
    }

    private static var bundledConfig: [String: Any] {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ) as? [String: Any] else {
            return [:]
        }
        return plist
    }

    private static func usableSecret(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("$("),
              trimmed != "MISSING_HMAC_SECRET" else {
            return nil
        }
        return trimmed
    }
}

enum APIFlowError: LocalizedError {
    case missingHMACSecret
    case missingToken
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingHMACSecret:
            return "HMAC secret is not configured."
        case .missingToken:
            return "Authorization required."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case let .server(_, message):
            return message?.isEmpty == false ? message : "Server request failed."
        }
    }
}
