import CryptoKit
import Foundation

final class HMACRequestBuilder {
    private let deviceIdentityProvider: DeviceIdentityProvider

    init(deviceIdentityProvider: DeviceIdentityProvider) {
        self.deviceIdentityProvider = deviceIdentityProvider
    }

    func buildAuthRequest() throws -> AuthTokenRequest {
        let secret = AppConstants.hmacSecret
        guard !secret.isEmpty else {
            throw APIFlowError.missingHMACSecret
        }

        let deviceID = deviceIdentityProvider.deviceID()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        let hmacInput = "\(deviceID)/\(timestamp)/\(nonce)"
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(hmacInput.utf8), using: key)
        let hmacHash = Data(signature).base64EncodedString()

        return AuthTokenRequest(
            deviceId: deviceID,
            timestamp: timestamp,
            nonce: nonce,
            hmacHash: hmacHash
        )
    }
}
