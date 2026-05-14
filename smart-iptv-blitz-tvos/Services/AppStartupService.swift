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

        async let shouldShowDisclaimer = disclaimerService.shouldShowDisclaimer()
        async let hasSyncedPlaylist = playlistService.syncActivePlaylistOnStartup()

        if await shouldShowDisclaimer {
            return (.disclaimer, nil)
        }

        if await hasSyncedPlaylist {
            return (.home, nil)
        }

        let decision = await authDeviceService.resolveStartupDestination()
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
