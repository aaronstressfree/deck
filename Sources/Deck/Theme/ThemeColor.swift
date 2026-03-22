import SwiftUI
import AppKit

/// A platform-agnostic, Codable color representation.
/// Converts to SwiftUI Color, NSColor, and can be used with SwiftTerm.
struct ThemeColor: Codable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    /// Initialize from hex string: "#3B82F6" or "3B82F6"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        if hex.count == 8 {
            // RRGGBBAA
            self.red = Double((rgb >> 24) & 0xFF) / 255.0
            self.green = Double((rgb >> 16) & 0xFF) / 255.0
            self.blue = Double((rgb >> 8) & 0xFF) / 255.0
            self.opacity = Double(rgb & 0xFF) / 255.0
        } else {
            // RRGGBB
            self.red = Double((rgb >> 16) & 0xFF) / 255.0
            self.green = Double((rgb >> 8) & 0xFF) / 255.0
            self.blue = Double(rgb & 0xFF) / 255.0
            self.opacity = 1.0
        }
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: opacity)
    }

    var hexString: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Returns a new ThemeColor with modified opacity
    func withOpacity(_ newOpacity: Double) -> ThemeColor {
        ThemeColor(red: red, green: green, blue: blue, opacity: newOpacity)
    }
}
