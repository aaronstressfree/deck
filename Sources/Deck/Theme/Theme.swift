import Foundation

// MARK: - ANSI Palette

struct AnsiPalette: Codable, Hashable, Sendable {
    var black: ThemeColor
    var red: ThemeColor
    var green: ThemeColor
    var yellow: ThemeColor
    var blue: ThemeColor
    var magenta: ThemeColor
    var cyan: ThemeColor
    var white: ThemeColor
    var brightBlack: ThemeColor
    var brightRed: ThemeColor
    var brightGreen: ThemeColor
    var brightYellow: ThemeColor
    var brightBlue: ThemeColor
    var brightMagenta: ThemeColor
    var brightCyan: ThemeColor
    var brightWhite: ThemeColor
}

// MARK: - Terminal Colors

struct TerminalColors: Codable, Hashable, Sendable {
    var background: ThemeColor
    var foreground: ThemeColor
    var cursor: ThemeColor
    var cursorText: ThemeColor
    var selection: ThemeColor
    var ansi: AnsiPalette
}

// MARK: - Surface Colors

struct SurfaceColors: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var inset: ThemeColor
    var elevated: ThemeColor
    var overlay: ThemeColor
    var hover: ThemeColor
    var active: ThemeColor
    var selected: ThemeColor
    var selectedHover: ThemeColor
    var bar: ThemeColor
    var subtle: ThemeColor
}

// MARK: - Border Colors

struct BorderColors: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var hover: ThemeColor
    var selected: ThemeColor
    var focused: ThemeColor
    var subtle: ThemeColor
    var error: ThemeColor
    var warning: ThemeColor
}

// MARK: - Text Colors

struct TextColors: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var secondary: ThemeColor
    var tertiary: ThemeColor
    var quaternary: ThemeColor
    var onAccent: ThemeColor
    var onError: ThemeColor
    var link: ThemeColor
}

// MARK: - Icon Colors

struct IconColors: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var secondary: ThemeColor
    var tertiary: ThemeColor
    var onAccent: ThemeColor
}

// MARK: - Accent Colors

struct AccentColors: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var hover: ThemeColor
    var active: ThemeColor
    var subtle: ThemeColor
    var muted: ThemeColor
}

// MARK: - Status Colors

struct StatusColor: Codable, Hashable, Sendable {
    var primary: ThemeColor
    var subtle: ThemeColor
    var border: ThemeColor
}

struct StatusColors: Codable, Hashable, Sendable {
    var error: StatusColor
    var warning: StatusColor
    var success: StatusColor
    var info: StatusColor
}

// MARK: - Interactive Colors

struct InteractiveColors: Codable, Hashable, Sendable {
    var focusRing: ThemeColor
    var scrollbarThumb: ThemeColor
    var scrollbarThumbHover: ThemeColor
    var scrollbarTrack: ThemeColor
    var searchMatch: ThemeColor
    var searchMatchActive: ThemeColor
    var dropTarget: ThemeColor
    var dropTargetBorder: ThemeColor
}

// MARK: - Theme Metadata

enum ColorSchemeType: String, Codable, Sendable {
    case dark
    case light
}

struct ThemeMetadata: Codable, Hashable, Sendable {
    var id: String
    var name: String
    var author: String
    var version: Int
    var colorScheme: ColorSchemeType
    var description: String?
    var isBuiltIn: Bool
}

// MARK: - Theme

struct Theme: Codable, Hashable, Sendable, Identifiable {
    var metadata: ThemeMetadata
    var surfaces: SurfaceColors
    var borders: BorderColors
    var text: TextColors
    var icons: IconColors
    var accent: AccentColors
    var status: StatusColors
    var interactive: InteractiveColors
    var terminal: TerminalColors

    var id: String { metadata.id }
}
