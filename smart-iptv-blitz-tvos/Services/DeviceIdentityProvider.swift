import CryptoKit
import Foundation
import UIKit

final class DeviceIdentityProvider {
    private let preferences: PreferenceStore

    init(preferences: PreferenceStore) {
        self.preferences = preferences
    }

    func deviceID() -> String {
        let stored = preferences.string(forKey: PreferenceKeys.stableDeviceSeed)
        if !stored.isEmpty {
            return stored
        }

        let base = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let generated = generate8DigitAlphanumeric(from: base)
        preferences.set(generated, forKey: PreferenceKeys.stableDeviceSeed)
        return generated
    }

    var platformName: String {
        UIDevice.current.model.isEmpty ? "apple_tv" : UIDevice.current.model
    }

    var regionCode: String? {
        Locale.current.region?.identifier
    }

    private func generate8DigitAlphanumeric(from input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return digest.prefix(8).map { byte in
            String(alphabet[Int(byte) % alphabet.count])
        }.joined()
    }
}
