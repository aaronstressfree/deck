import Foundation

/// Manages the Anthropic API key — defaults to the built-in key,
/// with an optional user override via Settings.
enum APIKeyStore {
    private static let defaultKey = "" // Set your Anthropic API key in Settings, or set ANTHROPIC_API_KEY env var
    private static let userDefaultsKey = "anthropicApiKey"

    /// The active API key: user override if set, otherwise the built-in default.
    static var apiKey: String {
        let custom = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        return custom.isEmpty ? defaultKey : custom
    }

    /// Whether the user has set a custom key.
    static var isUsingCustomKey: Bool {
        let custom = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
        return !custom.isEmpty
    }
}
