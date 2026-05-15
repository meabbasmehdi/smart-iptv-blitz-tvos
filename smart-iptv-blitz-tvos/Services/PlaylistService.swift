import Foundation

enum PlaylistStartupSyncResult {
    case activePlaylist
    case noPlaylists
    case needsSelection
    case failed
}

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

    func syncActivePlaylistOnStartup() async -> PlaylistStartupSyncResult {
        guard let playlists = try? await fetchPlaylists() else {
            clearActivePlaylist()
            return .failed
        }

        guard !playlists.isEmpty else {
            clearActivePlaylist()
            return .noPlaylists
        }

        guard let storedID = preferences.int64(forKey: PreferenceKeys.activePlaylistID),
              let selected = playlists.first(where: { $0.id == storedID }) else {
            clearActivePlaylist()
            return .needsSelection
        }

        preferences.set(selected.id, forKey: PreferenceKeys.activePlaylistID)
        preferences.set(selected.source.rawValue, forKey: PreferenceKeys.activePlaylistSource)
        preferences.set(selected.title, forKey: PreferenceKeys.activePlaylistTitle)
        return .activePlaylist
    }

    func selectActivePlaylist(_ playlist: PlaylistResponse) {
        guard let playlistID = playlist.id else {
            return
        }

        preferences.set(playlistID, forKey: PreferenceKeys.activePlaylistID)
        preferences.set(playlist.source.rawValue, forKey: PreferenceKeys.activePlaylistSource)
        preferences.set(playlist.title, forKey: PreferenceKeys.activePlaylistTitle)
    }

    func addDefaultPlaylistAndSelect() async throws -> PlaylistResponse {
        let token = try await authDeviceService.ensureValidToken()
        let response = try await apiClient.request(
            DefaultPlaylistResponse.self,
            path: "iptv/smart/playlist/default/detail/",
            method: .get,
            bearerToken: "Bearer \(token)",
            queryItems: [
                URLQueryItem(name: "device_id", value: deviceIdentityProvider.deviceID())
            ]
        )

        guard response.success else {
            throw APIFlowError.server(
                statusCode: 200,
                message: response.message ?? "Unable to load the default playlist."
            )
        }

        let playlists = try await fetchPlaylists()
        guard let selected = playlists.first(where: { $0.source == .default || $0.source == .demo })
            ?? playlists.first else {
            throw APIFlowError.invalidResponse
        }

        selectActivePlaylist(selected)
        return selected
    }

    private func clearActivePlaylist() {
        preferences.remove(PreferenceKeys.activePlaylistID)
        preferences.remove(PreferenceKeys.activePlaylistSource)
        preferences.remove(PreferenceKeys.activePlaylistTitle)
    }
}
