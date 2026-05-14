import Foundation

final class DisclaimerService {
    private let apiClient: APIClient
    private let authDeviceService: AuthDeviceService
    private let preferences: PreferenceStore

    init(apiClient: APIClient, authDeviceService: AuthDeviceService, preferences: PreferenceStore) {
        self.apiClient = apiClient
        self.authDeviceService = authDeviceService
        self.preferences = preferences
    }

    func fetchLatestDisclaimer(version: String?) async throws -> AppDisclaimerResponse {
        let token = try await authDeviceService.ensureValidToken()
        let queryItems = version?.isEmpty == false
            ? [URLQueryItem(name: "version", value: version)]
            : []
        return try await apiClient.request(
            AppDisclaimerResponse.self,
            path: "iptv/smart/disclaimer/app/",
            method: .get,
            bearerToken: "Bearer \(token)",
            queryItems: queryItems
        )
    }

    func shouldShowDisclaimer() async -> Bool {
        let hasAcceptedDisclaimer = preferences.bool(forKey: PreferenceKeys.disclaimerAccepted)
        if !hasAcceptedDisclaimer {
            return true
        }

        let storedVersion = preferences.string(forKey: PreferenceKeys.disclaimerVersion)
        guard (try? await authDeviceService.ensureValidToken()) != nil else {
            return false
        }

        do {
            let latest = try await fetchLatestDisclaimer(version: storedVersion)
            let latestVersion = latest.version?.isEmpty == false ? latest.version! : storedVersion
            if !latestVersion.isEmpty && latestVersion != storedVersion {
                preferences.set(false, forKey: PreferenceKeys.disclaimerAccepted)
                return true
            }
        } catch {
            return false
        }
        return false
    }

    func accept(version: String?) {
        if let version, !version.isEmpty {
            preferences.set(version, forKey: PreferenceKeys.disclaimerVersion)
        }
        preferences.set(true, forKey: PreferenceKeys.disclaimerAccepted)
    }
}
