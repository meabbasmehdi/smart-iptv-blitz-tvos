import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var activePlaylistTitle: String

    private let preferences: PreferenceStore

    init(preferences: PreferenceStore) {
        self.preferences = preferences
        activePlaylistTitle = Self.activePlaylistTitle(from: preferences)
    }

    func refreshActivePlaylist() {
        activePlaylistTitle = Self.activePlaylistTitle(from: preferences)
    }

    private static func activePlaylistTitle(from preferences: PreferenceStore) -> String {
        let title = preferences.string(forKey: PreferenceKeys.activePlaylistTitle)
        return title.isEmpty ? "Smart IPTV" : title
    }
}
