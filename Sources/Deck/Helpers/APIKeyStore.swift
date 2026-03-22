import Foundation

/// Manages the Anthropic API key.
/// No built-in key — users provide their own via Settings.
/// The app works fully without one; AI features (naming, project enhancement)
/// are progressive enhancements that activate when a key is set.
enum APIKeyStore {
    private static let userDefaultsKey = "anthropicApiKey"

    /// The API key, if the user has set one. Empty string = no key.
    static var apiKey: String {
        UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
    }

    /// Whether an API key is available for AI features.
    static var hasKey: Bool {
        !apiKey.isEmpty
    }

    /// Whether the user has set a custom key.
    static var isUsingCustomKey: Bool {
        hasKey
    }

    /// Save a user-provided API key.
    static func setKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: userDefaultsKey)
    }

    /// Clear the stored key.
    static func clearKey() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
