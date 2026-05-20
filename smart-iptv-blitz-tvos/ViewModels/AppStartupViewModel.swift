import Combine
import Foundation

@MainActor
final class AppStartupViewModel: ObservableObject {
    @Published private(set) var route: AppRoute?
    @Published var snackBarMessage: String?

    private let startupService: AppStartupService
    private var hasStarted = false

    init(startupService: AppStartupService) {
        self.startupService = startupService
    }

    func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        let result = await startupService.resolveInitialRoute()
        route = result.route
        snackBarMessage = result.message
    }

    func routeToPlaylists() {
        route = .playlists
    }

    func routeToCreatePlaylist() {
        route = .createPlaylist
    }

    func routeToHome() {
        route = .home
    }

    func routeToLiveTV() {
        route = .liveTV
    }

    func routeToPlayer() {
        route = .player
    }
}
