import Foundation

final class AuthDeviceService {
    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let hmacRequestBuilder: HMACRequestBuilder
    private let deviceIdentityProvider: DeviceIdentityProvider
    private let preferences: PreferenceStore

    init(
        apiClient: APIClient,
        tokenStore: TokenStore,
        hmacRequestBuilder: HMACRequestBuilder,
        deviceIdentityProvider: DeviceIdentityProvider,
        preferences: PreferenceStore
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.hmacRequestBuilder = hmacRequestBuilder
        self.deviceIdentityProvider = deviceIdentityProvider
        self.preferences = preferences
    }

    func registerDeviceOnLaunch() async -> Bool {
        do {
            let token = try await ensureValidToken()
            return await registerDevice(bearer: "Bearer \(token)", deviceID: deviceIdentityProvider.deviceID())
        } catch {
            return false
        }
    }

    func resolveStartupDestination(registerBeforeCheck: Bool = true) async -> StartupDecision {
        let deviceID = deviceIdentityProvider.deviceID()

        do {
            let token = try await ensureValidToken()
            let bearer = "Bearer \(token)"

            if registerBeforeCheck {
                _ = await registerDevice(bearer: bearer, deviceID: deviceID)
            }

            do {
                let status = try await checkDevice(bearer: bearer, deviceID: deviceID)
                return await decide(from: status, bearer: bearer, deviceID: deviceID)
            } catch {
                let tokenStillValid = await validateToken(bearer: bearer)
                if !tokenStillValid,
                   let refreshedToken = try? await requestNewToken() {
                    let refreshedBearer = "Bearer \(refreshedToken)"
                    if let retryStatus = try? await checkDevice(bearer: refreshedBearer, deviceID: deviceID) {
                        return await decide(
                            from: retryStatus,
                            bearer: refreshedBearer,
                            deviceID: deviceID
                        )
                    }
                    let registered = await registerDevice(bearer: refreshedBearer, deviceID: deviceID)
                    return registered
                        ? .success(.onboarding)
                        : .failure(message: "Device registration failed.", fallback: .onboarding)
                }

                return .failure(
                    message: error.localizedDescription,
                    fallback: .onboarding
                )
            }
        } catch {
            return .failure(
                message: "Unable to authenticate device.",
                fallback: .onboarding
            )
        }
    }

    func ensureValidToken() async throws -> String {
        if let token = tokenStore.validToken() {
            return token
        }
        return try await requestNewToken()
    }

    private func requestNewToken() async throws -> String {
        let authRequest = try hmacRequestBuilder.buildAuthRequest()
        let response = try await apiClient.request(
            AuthTokenResponse.self,
            path: "iptv/smart/auth/token/",
            method: .post,
            body: authRequest
        )

        guard let token = response.token, !token.isEmpty else {
            throw APIFlowError.missingToken
        }

        APIDebugLogger.log("auth token received token=\(token)")

        let expiryMillis = response.expiresAt.flatMap(Double.init).map { $0 * 1000 }
        tokenStore.store(token: token, expiryTimestampMillis: expiryMillis)
        return token
    }

    private func validateToken(bearer: String) async -> Bool {
        do {
            let response = try await apiClient.request(
                TokenValidationResponse.self,
                path: "iptv/smart/auth/check/",
                method: .post,
                bearerToken: bearer
            )
            return response.success == true
        } catch {
            return false
        }
    }

    private func registerDevice(bearer: String, deviceID: String) async -> Bool {
        let request = DeviceRegistrationRequest(
            deviceId: deviceID,
            deviceType: "apple_tv",
            appVersion: AppConstants.appVersion,
            platform: deviceIdentityProvider.platformName,
            region: deviceIdentityProvider.regionCode
        )

        do {
            let response = try await apiClient.request(
                DeviceRegistrationResponse.self,
                path: "iptv/smart/device/add/",
                method: .post,
                bearerToken: bearer,
                body: request
            )
            return response.success
        } catch {
            return false
        }
    }

    private func checkDevice(bearer: String, deviceID: String) async throws -> DeviceStatusResponse {
        try await apiClient.request(
            DeviceStatusResponse.self,
            path: "iptv/smart/device/check/\(deviceID)/",
            method: .get,
            bearerToken: bearer
        )
    }

    private func decide(
        from statusResponse: DeviceStatusResponse?,
        bearer: String,
        deviceID: String
    ) async -> StartupDecision {
        let onboardingCompletedLocally = preferences.bool(
            forKey: PreferenceKeys.playlistOnboardingComplete,
            default: false
        )
        let isActive = statusResponse?.success == true &&
            statusResponse?.status?.caseInsensitiveCompare("active") == .orderedSame
        let onboardingDone = onboardingCompletedLocally || statusResponse?.onboardingCompleted == true

        if isActive {
            return onboardingDone ? .success(.home) : .success(.onboarding)
        }

        if statusResponse?.success == true && statusResponse?.exists == true {
            return .success(.onboarding)
        }

        let registered = await registerDevice(bearer: bearer, deviceID: deviceID)
        if registered {
            return .success(.onboarding)
        }

        return .failure(
            message: statusResponse?.message ?? "Device is not active.",
            fallback: .onboarding
        )
    }
}
