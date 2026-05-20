import Foundation

final class PreferenceStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func string(forKey key: String, default defaultValue: String = "") -> String {
        defaults.string(forKey: key) ?? defaultValue
    }

    func stringOptional(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func set(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func int64(forKey key: String) -> Int64? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return Int64(defaults.integer(forKey: key))
    }

    func set(_ value: Int64?, forKey key: String) {
        if let value {
            defaults.set(Int(value), forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func remove(_ key: String) {
        defaults.removeObject(forKey: key)
    }
}
