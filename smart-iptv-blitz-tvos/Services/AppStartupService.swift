import Foundation

final class AppStartupService {
    private let authDeviceService: AuthDeviceService
    private let disclaimerService: DisclaimerService
    private let playlistService: PlaylistService

    init(
        authDeviceService: AuthDeviceService,
        disclaimerService: DisclaimerService,
        playlistService: PlaylistService
    ) {
        self.authDeviceService = authDeviceService
        self.disclaimerService = disclaimerService
        self.playlistService = playlistService
    }

    func resolveInitialRoute() async -> (route: AppRoute, message: String?) {
        _ = await authDeviceService.registerDeviceOnLaunch()

        if await disclaimerService.shouldShowDisclaimer() {
            return (.disclaimer, nil)
        }

        switch await playlistService.syncActivePlaylistOnStartup() {
        case .activePlaylist:
            return (.home, nil)
        case .noPlaylists:
            return (.createPlaylist, nil)
        case .needsSelection, .failed:
            break
        }

        let decision = await authDeviceService.resolveStartupDestination(registerBeforeCheck: false)
        switch decision {
        case let .success(target, message):
            return (map(target: target), message)
        case let .failure(message, fallback):
            return (map(target: fallback), message)
        }
    }

    private func map(target: StartupTarget) -> AppRoute {
        switch target {
        case .home:
            return .home
        case .onboarding:
            return .playlists
        }
    }
}
