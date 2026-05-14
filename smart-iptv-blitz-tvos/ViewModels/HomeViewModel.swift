import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var activePlaylistTitle: String

    init(preferences: PreferenceStore) {
        let title = preferences.string(forKey: PreferenceKeys.activePlaylistTitle)
        activePlaylistTitle = title.isEmpty ? "Smart IPTV" : title
    }
}
