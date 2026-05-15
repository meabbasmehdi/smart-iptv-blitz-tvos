import Combine
import Foundation

@MainActor
final class CreatePlaylistViewModel: ObservableObject {
    @Published private(set) var isAddingDemoPlaylist = false
    @Published var errorMessage: String?

    private let playlistService: PlaylistService

    init(playlistService: PlaylistService) {
        self.playlistService = playlistService
    }

    func addDemoPlaylist() async -> Bool {
        guard !isAddingDemoPlaylist else { return false }

        isAddingDemoPlaylist = true
        errorMessage = nil
        defer { isAddingDemoPlaylist = false }

        do {
            _ = try await playlistService.addDefaultPlaylistAndSelect()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
