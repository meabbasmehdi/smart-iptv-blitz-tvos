import Foundation

final class AppContainer {
    let preferences: PreferenceStore
    let tokenStore: TokenStore
    let deviceIdentityProvider: DeviceIdentityProvider
    let authDeviceService: AuthDeviceService
    let disclaimerService: DisclaimerService
    let playlistService: PlaylistService
    let startupService: AppStartupService

    static let live = AppContainer()

    init() {
        let preferences = PreferenceStore()
        let tokenStore = TokenStore()
        let apiClient = APIClient()
        let deviceIdentityProvider = DeviceIdentityProvider(preferences: preferences)
        let hmacBuilder = HMACRequestBuilder(deviceIdentityProvider: deviceIdentityProvider)
        let authDeviceService = AuthDeviceService(
            apiClient: apiClient,
            tokenStore: tokenStore,
            hmacRequestBuilder: hmacBuilder,
            deviceIdentityProvider: deviceIdentityProvider,
            preferences: preferences
        )
        let disclaimerService = DisclaimerService(
            apiClient: apiClient,
            authDeviceService: authDeviceService,
            preferences: preferences
        )
        let playlistService = PlaylistService(
            apiClient: apiClient,
            authDeviceService: authDeviceService,
            deviceIdentityProvider: deviceIdentityProvider,
            preferences: preferences
        )

        self.preferences = preferences
        self.tokenStore = tokenStore
        self.deviceIdentityProvider = deviceIdentityProvider
        self.authDeviceService = authDeviceService
        self.disclaimerService = disclaimerService
        self.playlistService = playlistService
        self.startupService = AppStartupService(
            authDeviceService: authDeviceService,
            disclaimerService: disclaimerService,
            playlistService: playlistService
        )
    }
}
