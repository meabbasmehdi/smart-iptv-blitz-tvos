import Foundation

final class PlaylistService {
    private let apiClient: APIClient
    private let authDeviceService: AuthDeviceService
    private let deviceIdentityProvider: DeviceIdentityProvider
    private let preferences: PreferenceStore

    init(
        apiClient: APIClient,
        authDeviceService: AuthDeviceService,
        deviceIdentityProvider: DeviceIdentityProvider,
        preferences: PreferenceStore
    ) {
        self.apiClient = apiClient
        self.authDeviceService = authDeviceService
        self.deviceIdentityProvider = deviceIdentityProvider
        self.preferences = preferences
    }

    func fetchPlaylists() async throws -> [PlaylistResponse] {
        let token = try await authDeviceService.ensureValidToken()
        let response = try await apiClient.request(
            PlaylistListResponse.self,
            path: "iptv/smart/playlist/list/",
            method: .get,
            bearerToken: "Bearer \(token)",
            queryItems: [
                URLQueryItem(name: "device_id", value: deviceIdentityProvider.deviceID())
            ]
        )
        return response.data ?? []
    }

    func syncActivePlaylistOnStartup() async -> Bool {
        guard let playlists = try? await fetchPlaylists() else {
            clearActivePlaylist()
            return false
        }

        guard !playlists.isEmpty else {
            clearActivePlaylist()
            return false
        }

        guard let storedID = preferences.int64(forKey: PreferenceKeys.activePlaylistID),
              let selected = playlists.first(where: { $0.id == storedID }) else {
            clearActivePlaylist()
            return false
        }

        preferences.set(selected.id, forKey: PreferenceKeys.activePlaylistID)
        preferences.set(selected.source.rawValue, forKey: PreferenceKeys.activePlaylistSource)
        preferences.set(selected.title, forKey: PreferenceKeys.activePlaylistTitle)
        return true
    }

    private func clearActivePlaylist() {
        preferences.remove(PreferenceKeys.activePlaylistID)
        preferences.remove(PreferenceKeys.activePlaylistSource)
        preferences.remove(PreferenceKeys.activePlaylistTitle)
    }
}
