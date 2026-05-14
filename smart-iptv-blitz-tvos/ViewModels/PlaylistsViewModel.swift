import Combine
import Foundation

@MainActor
final class PlaylistsViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var playlists: [PlaylistResponse] = []
    @Published var errorMessage: String?

    private let playlistService: PlaylistService
    private var hasLoaded = false

    init(playlistService: PlaylistService) {
        self.playlistService = playlistService
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            playlists = try await playlistService.fetchPlaylists()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            playlists = []
            isLoading = false
        }
    }
}
