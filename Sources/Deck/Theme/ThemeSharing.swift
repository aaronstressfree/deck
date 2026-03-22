import Foundation
import AppKit

/// Encodes and decodes themes as shareable `deck://theme/<data>` URLs.
/// The theme JSON is zlib-compressed and base64url-encoded so the entire
/// theme travels inside the URL itself — no server required.
enum ThemeSharing {

    static let urlScheme = "deck"
    static let themePath = "theme"

    // MARK: - Encode

    /// Generate a shareable URL string for a theme.
    static func shareURL(for theme: Theme) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // compact, deterministic

        guard let json = try? encoder.encode(theme),
              let compressed = try? (json as NSData).compressed(using: .zlib) as Data
        else { return nil }

        let base64url = compressed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return "\(urlScheme)://\(themePath)/\(base64url)"
    }

    // MARK: - Decode

    /// Decode a theme from a `deck://theme/<data>` URL.
    static func theme(from url: URL) -> Theme? {
        guard url.scheme == urlScheme,
              url.host == themePath
        else { return nil }

        let encoded = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !encoded.isEmpty else { return nil }
        return decodeTheme(from: encoded)
    }

    /// Decode a theme from the raw base64url payload.
    static func decodeTheme(from encoded: String) -> Theme? {
        var base64 = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }

        guard let compressed = Data(base64Encoded: base64),
              let json = try? (compressed as NSData).decompressed(using: .zlib) as Data,
              let theme = try? JSONDecoder().decode(Theme.self, from: json)
        else { return nil }

        return theme
    }

    /// Check whether a string looks like a Deck theme share link.
    static func isShareURL(_ string: String) -> Bool {
        string.hasPrefix("\(urlScheme)://\(themePath)/")
    }

    // MARK: - Clipboard helpers

    /// Copy the share link for a theme to the system pasteboard.
    /// Returns `true` on success.
    @discardableResult
    static func copyToClipboard(theme: Theme) -> Bool {
        guard let link = shareURL(for: theme) else { return false }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(link, forType: .string)
        return true
    }

    /// Read a theme from the system pasteboard if it contains a share link.
    static func themeFromClipboard() -> Theme? {
        guard let string = NSPasteboard.general.string(forType: .string),
              isShareURL(string),
              let url = URL(string: string)
        else { return nil }
        return theme(from: url)
    }
}
