import Foundation
import Security

struct TokenInfo {
    let token: String
    let expiresAt: Date
    let refreshedAt: Date
}

final class TokenStore {
    private enum Keys {
        static let expiry = "auth_token_expiry"
        static let refreshTime = "auth_token_refresh_time"
    }

    private let service = "com.invotyx.smartiptv.auth"
    private let account = "jwt"
    private let defaults: UserDefaults
    private var cachedTokenInfo: TokenInfo?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func store(token: String, expiryTimestampMillis: TimeInterval?) {
        let now = Date()
        let expiry = expiryTimestampMillis.map { Date(timeIntervalSince1970: $0 / 1000) }
            ?? now.addingTimeInterval(AppConstants.tokenRefreshFallbackSeconds)

        writeToken(token)
        defaults.set(expiry.timeIntervalSince1970, forKey: Keys.expiry)
        defaults.set(now.timeIntervalSince1970, forKey: Keys.refreshTime)
        cachedTokenInfo = TokenInfo(token: token, expiresAt: expiry, refreshedAt: now)
    }

    func clearToken() {
        deleteToken()
        defaults.removeObject(forKey: Keys.expiry)
        defaults.removeObject(forKey: Keys.refreshTime)
        cachedTokenInfo = nil
    }

    func storedTokenInfo() -> TokenInfo? {
        if let cachedTokenInfo {
            return cachedTokenInfo
        }
        guard let token = readToken(), !token.isEmpty else {
            return nil
        }
        let expiryTime = defaults.double(forKey: Keys.expiry)
        guard expiryTime > 0 else {
            return nil
        }
        let refreshedAt = Date(timeIntervalSince1970: defaults.double(forKey: Keys.refreshTime))
        let info = TokenInfo(
            token: token,
            expiresAt: Date(timeIntervalSince1970: expiryTime),
            refreshedAt: refreshedAt
        )
        cachedTokenInfo = info
        return info
    }

    func validToken() -> String? {
        guard let info = storedTokenInfo(), info.expiresAt > Date(), !info.token.isEmpty else {
            return nil
        }
        return info.token
    }

    private func readToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func writeToken(_ token: String) {
        deleteToken()
        var item = baseQuery()
        item[kSecValueData as String] = Data(token.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private func deleteToken() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
