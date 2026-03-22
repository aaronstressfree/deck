import Foundation

// MARK: - Obsidian (Default Dark)

extension Theme {
    static let obsidian = Theme(
        metadata: ThemeMetadata(
            id: "obsidian",
            name: "Obsidian",
            author: "Deck",
            version: 1,
            colorScheme: .dark,
            description: "Deep, warm-neutral dark theme",
            isBuiltIn: true
        ),
        surfaces: SurfaceColors(
            primary: ThemeColor(hex: "18181B"),
            inset: ThemeColor(hex: "131316"),
            elevated: ThemeColor(hex: "222226"),
            overlay: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.55),
            hover: ThemeColor(hex: "2A2A2F"),
            active: ThemeColor(hex: "333338"),
            selected: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.12),
            selectedHover: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.18),
            bar: ThemeColor(hex: "131316"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.03)
        ),
        borders: BorderColors(
            primary: ThemeColor(hex: "27272B"),
            hover: ThemeColor(hex: "3F3F46"),
            selected: ThemeColor(hex: "3B82F6"),
            focused: ThemeColor(hex: "3B82F6"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.06),
            error: ThemeColor(hex: "EF4444"),
            warning: ThemeColor(hex: "F59E0B")
        ),
        text: TextColors(
            primary: ThemeColor(hex: "E4E4E7"),
            secondary: ThemeColor(hex: "A1A1AA"),
            tertiary: ThemeColor(hex: "71717A"),
            quaternary: ThemeColor(hex: "52525B"),
            onAccent: ThemeColor(hex: "FFFFFF"),
            onError: ThemeColor(hex: "FFFFFF"),
            link: ThemeColor(hex: "60A5FA")
        ),
        icons: IconColors(
            primary: ThemeColor(hex: "D4D4D8"),
            secondary: ThemeColor(hex: "71717A"),
            tertiary: ThemeColor(hex: "52525B"),
            onAccent: ThemeColor(hex: "FFFFFF")
        ),
        accent: AccentColors(
            primary: ThemeColor(hex: "3B82F6"),
            hover: ThemeColor(hex: "60A5FA"),
            active: ThemeColor(hex: "2563EB"),
            subtle: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.15),
            muted: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.08)
        ),
        status: StatusColors(
            error: StatusColor(
                primary: ThemeColor(hex: "EF4444"),
                subtle: ThemeColor(hex: "3B1818"),
                border: ThemeColor(red: 0.937, green: 0.267, blue: 0.267, opacity: 0.40)
            ),
            warning: StatusColor(
                primary: ThemeColor(hex: "F59E0B"),
                subtle: ThemeColor(hex: "3B2E10"),
                border: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.40)
            ),
            success: StatusColor(
                primary: ThemeColor(hex: "22C55E"),
                subtle: ThemeColor(hex: "14332A"),
                border: ThemeColor(red: 0.133, green: 0.773, blue: 0.369, opacity: 0.40)
            ),
            info: StatusColor(
                primary: ThemeColor(hex: "0EA5E9"),
                subtle: ThemeColor(hex: "0C2D48"),
                border: ThemeColor(red: 0.055, green: 0.647, blue: 0.914, opacity: 0.40)
            )
        ),
        interactive: InteractiveColors(
            focusRing: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.50),
            scrollbarThumb: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.12),
            scrollbarThumbHover: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.20),
            scrollbarTrack: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0),
            searchMatch: ThemeColor(red: 0.980, green: 0.800, blue: 0.082, opacity: 0.25),
            searchMatchActive: ThemeColor(red: 0.980, green: 0.800, blue: 0.082, opacity: 0.50),
            dropTarget: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.15),
            dropTargetBorder: ThemeColor(hex: "3B82F6")
        ),
        terminal: TerminalColors(
            background: ThemeColor(hex: "131316"),
            foreground: ThemeColor(hex: "C8C8CD"),
            cursor: ThemeColor(hex: "3B82F6"),
            cursorText: ThemeColor(hex: "131316"),
            selection: ThemeColor(red: 0.231, green: 0.510, blue: 0.965, opacity: 0.25),
            ansi: AnsiPalette(
                black: ThemeColor(hex: "2A2A2F"),
                red: ThemeColor(hex: "F07070"),
                green: ThemeColor(hex: "50D080"),
                yellow: ThemeColor(hex: "E8C440"),
                blue: ThemeColor(hex: "60A0F0"),
                magenta: ThemeColor(hex: "B880F0"),
                cyan: ThemeColor(hex: "30D0E0"),
                white: ThemeColor(hex: "C8C8CD"),
                brightBlack: ThemeColor(hex: "52525B"),
                brightRed: ThemeColor(hex: "F0A0A0"),
                brightGreen: ThemeColor(hex: "80E0A8"),
                brightYellow: ThemeColor(hex: "F0D888"),
                brightBlue: ThemeColor(hex: "90C0F0"),
                brightMagenta: ThemeColor(hex: "D0B0F0"),
                brightCyan: ThemeColor(hex: "68D8E8"),
                brightWhite: ThemeColor(hex: "E4E4E7")
            ),
            fontFamily: "JetBrainsMono-Light"
        )
    )

    // MARK: - Porcelain (Light)

    static let porcelain = Theme(
        metadata: ThemeMetadata(
            id: "porcelain",
            name: "Porcelain",
            author: "Deck",
            version: 1,
            colorScheme: .light,
            description: "Clean, crisp light theme",
            isBuiltIn: true
        ),
        surfaces: SurfaceColors(
            primary: ThemeColor(hex: "FFFFFF"),
            inset: ThemeColor(hex: "F4F4F5"),
            elevated: ThemeColor(hex: "FFFFFF"),
            overlay: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.30),
            hover: ThemeColor(hex: "F4F4F5"),
            active: ThemeColor(hex: "E4E4E7"),
            selected: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.08),
            selectedHover: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.12),
            bar: ThemeColor(hex: "FAFAFA"),
            subtle: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.02)
        ),
        borders: BorderColors(
            primary: ThemeColor(hex: "E4E4E7"),
            hover: ThemeColor(hex: "D4D4D8"),
            selected: ThemeColor(hex: "2563EB"),
            focused: ThemeColor(hex: "2563EB"),
            subtle: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.06),
            error: ThemeColor(hex: "DC2626"),
            warning: ThemeColor(hex: "D97706")
        ),
        text: TextColors(
            primary: ThemeColor(hex: "18181B"),
            secondary: ThemeColor(hex: "52525B"),
            tertiary: ThemeColor(hex: "71717A"),
            quaternary: ThemeColor(hex: "A1A1AA"),
            onAccent: ThemeColor(hex: "FFFFFF"),
            onError: ThemeColor(hex: "FFFFFF"),
            link: ThemeColor(hex: "2563EB")
        ),
        icons: IconColors(
            primary: ThemeColor(hex: "18181B"),
            secondary: ThemeColor(hex: "71717A"),
            tertiary: ThemeColor(hex: "A1A1AA"),
            onAccent: ThemeColor(hex: "FFFFFF")
        ),
        accent: AccentColors(
            primary: ThemeColor(hex: "2563EB"),
            hover: ThemeColor(hex: "3B82F6"),
            active: ThemeColor(hex: "1D4ED8"),
            subtle: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.10),
            muted: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.05)
        ),
        status: StatusColors(
            error: StatusColor(
                primary: ThemeColor(hex: "DC2626"),
                subtle: ThemeColor(hex: "FEF2F2"),
                border: ThemeColor(red: 0.863, green: 0.149, blue: 0.149, opacity: 0.30)
            ),
            warning: StatusColor(
                primary: ThemeColor(hex: "D97706"),
                subtle: ThemeColor(hex: "FFFBEB"),
                border: ThemeColor(red: 0.851, green: 0.467, blue: 0.024, opacity: 0.30)
            ),
            success: StatusColor(
                primary: ThemeColor(hex: "16A34A"),
                subtle: ThemeColor(hex: "F0FDF4"),
                border: ThemeColor(red: 0.086, green: 0.639, blue: 0.290, opacity: 0.30)
            ),
            info: StatusColor(
                primary: ThemeColor(hex: "0891B2"),
                subtle: ThemeColor(hex: "ECFEFF"),
                border: ThemeColor(red: 0.031, green: 0.569, blue: 0.698, opacity: 0.30)
            )
        ),
        interactive: InteractiveColors(
            focusRing: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.50),
            scrollbarThumb: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.15),
            scrollbarThumbHover: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.25),
            scrollbarTrack: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0),
            searchMatch: ThemeColor(red: 0.980, green: 0.800, blue: 0.082, opacity: 0.30),
            searchMatchActive: ThemeColor(red: 0.980, green: 0.800, blue: 0.082, opacity: 0.60),
            dropTarget: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.10),
            dropTargetBorder: ThemeColor(hex: "2563EB")
        ),
        terminal: TerminalColors(
            background: ThemeColor(hex: "FAFAFA"),
            foreground: ThemeColor(hex: "18181B"),
            cursor: ThemeColor(hex: "2563EB"),
            cursorText: ThemeColor(hex: "FFFFFF"),
            selection: ThemeColor(red: 0.145, green: 0.388, blue: 0.922, opacity: 0.20),
            ansi: AnsiPalette(
                black: ThemeColor(hex: "18181B"),
                red: ThemeColor(hex: "DC2626"),
                green: ThemeColor(hex: "16A34A"),
                yellow: ThemeColor(hex: "CA8A04"),
                blue: ThemeColor(hex: "2563EB"),
                magenta: ThemeColor(hex: "9333EA"),
                cyan: ThemeColor(hex: "0891B2"),
                white: ThemeColor(hex: "D4D4D8"),
                brightBlack: ThemeColor(hex: "71717A"),
                brightRed: ThemeColor(hex: "EF4444"),
                brightGreen: ThemeColor(hex: "22C55E"),
                brightYellow: ThemeColor(hex: "EAB308"),
                brightBlue: ThemeColor(hex: "3B82F6"),
                brightMagenta: ThemeColor(hex: "A855F7"),
                brightCyan: ThemeColor(hex: "06B6D4"),
                brightWhite: ThemeColor(hex: "F4F4F5")
            ),
            fontFamily: "IBMPlexMono-Light"
        )
    )

    // MARK: - Ember (Warm Dark)

    static let ember = Theme(
        metadata: ThemeMetadata(
            id: "ember",
            name: "Ember",
            author: "Deck",
            version: 1,
            colorScheme: .dark,
            description: "Warm dark theme with amber accents",
            isBuiltIn: true
        ),
        surfaces: SurfaceColors(
            primary: ThemeColor(hex: "131110"),
            inset: ThemeColor(hex: "0E0C0A"),
            elevated: ThemeColor(hex: "1F1C19"),
            overlay: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.60),
            hover: ThemeColor(hex: "2A2622"),
            active: ThemeColor(hex: "33302B"),
            selected: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.12),
            selectedHover: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.18),
            bar: ThemeColor(hex: "0E0C0A"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.03)
        ),
        borders: BorderColors(
            primary: ThemeColor(hex: "2A2622"),
            hover: ThemeColor(hex: "3D3832"),
            selected: ThemeColor(hex: "F59E0B"),
            focused: ThemeColor(hex: "F59E0B"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.06),
            error: ThemeColor(hex: "EF4444"),
            warning: ThemeColor(hex: "F59E0B")
        ),
        text: TextColors(
            primary: ThemeColor(hex: "FAF7F2"),
            secondary: ThemeColor(hex: "A8A29E"),
            tertiary: ThemeColor(hex: "78716C"),
            quaternary: ThemeColor(hex: "57534E"),
            onAccent: ThemeColor(hex: "1C1917"),
            onError: ThemeColor(hex: "FFFFFF"),
            link: ThemeColor(hex: "FBBF24")
        ),
        icons: IconColors(
            primary: ThemeColor(hex: "D6D3D1"),
            secondary: ThemeColor(hex: "78716C"),
            tertiary: ThemeColor(hex: "57534E"),
            onAccent: ThemeColor(hex: "1C1917")
        ),
        accent: AccentColors(
            primary: ThemeColor(hex: "F59E0B"),
            hover: ThemeColor(hex: "FBBF24"),
            active: ThemeColor(hex: "D97706"),
            subtle: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.15),
            muted: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.08)
        ),
        status: StatusColors(
            error: StatusColor(
                primary: ThemeColor(hex: "EF4444"),
                subtle: ThemeColor(hex: "3B1818"),
                border: ThemeColor(red: 0.937, green: 0.267, blue: 0.267, opacity: 0.40)
            ),
            warning: StatusColor(
                primary: ThemeColor(hex: "F59E0B"),
                subtle: ThemeColor(hex: "3B2E10"),
                border: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.40)
            ),
            success: StatusColor(
                primary: ThemeColor(hex: "22C55E"),
                subtle: ThemeColor(hex: "14332A"),
                border: ThemeColor(red: 0.133, green: 0.773, blue: 0.369, opacity: 0.40)
            ),
            info: StatusColor(
                primary: ThemeColor(hex: "0EA5E9"),
                subtle: ThemeColor(hex: "0C2D48"),
                border: ThemeColor(red: 0.055, green: 0.647, blue: 0.914, opacity: 0.40)
            )
        ),
        interactive: InteractiveColors(
            focusRing: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.50),
            scrollbarThumb: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.12),
            scrollbarThumbHover: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.20),
            scrollbarTrack: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0),
            searchMatch: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.25),
            searchMatchActive: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.50),
            dropTarget: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.15),
            dropTargetBorder: ThemeColor(hex: "F59E0B")
        ),
        terminal: TerminalColors(
            background: ThemeColor(hex: "0E0C0A"),
            foreground: ThemeColor(hex: "D6D3D1"),
            cursor: ThemeColor(hex: "F59E0B"),
            cursorText: ThemeColor(hex: "0E0C0A"),
            selection: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.30),
            ansi: AnsiPalette(
                black: ThemeColor(hex: "2A2622"),
                red: ThemeColor(hex: "FB923C"),
                green: ThemeColor(hex: "4ADE80"),
                yellow: ThemeColor(hex: "FBBF24"),
                blue: ThemeColor(hex: "60A5FA"),
                magenta: ThemeColor(hex: "E879F9"),
                cyan: ThemeColor(hex: "22D3EE"),
                white: ThemeColor(hex: "D6D3D1"),
                brightBlack: ThemeColor(hex: "57534E"),
                brightRed: ThemeColor(hex: "FDBA74"),
                brightGreen: ThemeColor(hex: "86EFAC"),
                brightYellow: ThemeColor(hex: "FDE68A"),
                brightBlue: ThemeColor(hex: "93C5FD"),
                brightMagenta: ThemeColor(hex: "F0ABFC"),
                brightCyan: ThemeColor(hex: "67E8F9"),
                brightWhite: ThemeColor(hex: "FAF7F2")
            ),
            fontFamily: "SourceCodePro-Regular"
        )
    )

    // MARK: - Aurora (Green Accent Dark)

    static let aurora = Theme(
        metadata: ThemeMetadata(
            id: "aurora",
            name: "Aurora",
            author: "Deck",
            version: 1,
            colorScheme: .dark,
            description: "Cool dark theme with emerald accents",
            isBuiltIn: true
        ),
        surfaces: SurfaceColors(
            primary: ThemeColor(hex: "0F1117"),
            inset: ThemeColor(hex: "0A0C12"),
            elevated: ThemeColor(hex: "191C24"),
            overlay: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0.60),
            hover: ThemeColor(hex: "222630"),
            active: ThemeColor(hex: "2B3040"),
            selected: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.12),
            selectedHover: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.18),
            bar: ThemeColor(hex: "0A0C12"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.03)
        ),
        borders: BorderColors(
            primary: ThemeColor(hex: "222630"),
            hover: ThemeColor(hex: "353B4A"),
            selected: ThemeColor(hex: "10B981"),
            focused: ThemeColor(hex: "10B981"),
            subtle: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.06),
            error: ThemeColor(hex: "EF4444"),
            warning: ThemeColor(hex: "F59E0B")
        ),
        text: TextColors(
            primary: ThemeColor(hex: "F0F4F8"),
            secondary: ThemeColor(hex: "94A3B8"),
            tertiary: ThemeColor(hex: "64748B"),
            quaternary: ThemeColor(hex: "475569"),
            onAccent: ThemeColor(hex: "FFFFFF"),
            onError: ThemeColor(hex: "FFFFFF"),
            link: ThemeColor(hex: "34D399")
        ),
        icons: IconColors(
            primary: ThemeColor(hex: "CBD5E1"),
            secondary: ThemeColor(hex: "64748B"),
            tertiary: ThemeColor(hex: "475569"),
            onAccent: ThemeColor(hex: "FFFFFF")
        ),
        accent: AccentColors(
            primary: ThemeColor(hex: "10B981"),
            hover: ThemeColor(hex: "34D399"),
            active: ThemeColor(hex: "059669"),
            subtle: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.15),
            muted: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.08)
        ),
        status: StatusColors(
            error: StatusColor(
                primary: ThemeColor(hex: "EF4444"),
                subtle: ThemeColor(hex: "3B1818"),
                border: ThemeColor(red: 0.937, green: 0.267, blue: 0.267, opacity: 0.40)
            ),
            warning: StatusColor(
                primary: ThemeColor(hex: "F59E0B"),
                subtle: ThemeColor(hex: "3B2E10"),
                border: ThemeColor(red: 0.961, green: 0.620, blue: 0.043, opacity: 0.40)
            ),
            success: StatusColor(
                primary: ThemeColor(hex: "10B981"),
                subtle: ThemeColor(hex: "0D3025"),
                border: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.40)
            ),
            info: StatusColor(
                primary: ThemeColor(hex: "0EA5E9"),
                subtle: ThemeColor(hex: "0C2D48"),
                border: ThemeColor(red: 0.055, green: 0.647, blue: 0.914, opacity: 0.40)
            )
        ),
        interactive: InteractiveColors(
            focusRing: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.50),
            scrollbarThumb: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.12),
            scrollbarThumbHover: ThemeColor(red: 1, green: 1, blue: 1, opacity: 0.20),
            scrollbarTrack: ThemeColor(red: 0, green: 0, blue: 0, opacity: 0),
            searchMatch: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.25),
            searchMatchActive: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.50),
            dropTarget: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.15),
            dropTargetBorder: ThemeColor(hex: "10B981")
        ),
        terminal: TerminalColors(
            background: ThemeColor(hex: "0A0C12"),
            foreground: ThemeColor(hex: "CBD5E1"),
            cursor: ThemeColor(hex: "10B981"),
            cursorText: ThemeColor(hex: "0A0C12"),
            selection: ThemeColor(red: 0.063, green: 0.725, blue: 0.506, opacity: 0.30),
            ansi: AnsiPalette(
                black: ThemeColor(hex: "222630"),
                red: ThemeColor(hex: "F87171"),
                green: ThemeColor(hex: "34D399"),
                yellow: ThemeColor(hex: "FBBF24"),
                blue: ThemeColor(hex: "60A5FA"),
                magenta: ThemeColor(hex: "A78BFA"),
                cyan: ThemeColor(hex: "2DD4BF"),
                white: ThemeColor(hex: "CBD5E1"),
                brightBlack: ThemeColor(hex: "475569"),
                brightRed: ThemeColor(hex: "FCA5A5"),
                brightGreen: ThemeColor(hex: "6EE7B7"),
                brightYellow: ThemeColor(hex: "FDE68A"),
                brightBlue: ThemeColor(hex: "93C5FD"),
                brightMagenta: ThemeColor(hex: "C4B5FD"),
                brightCyan: ThemeColor(hex: "5EEAD4"),
                brightWhite: ThemeColor(hex: "F0F4F8")
            )
        )
    )

    /// All built-in themes
    static let builtInThemes: [Theme] = [
        .obsidian, .porcelain, .ember, .aurora,
        .midnightRose, .matcha, .cosmos, .copper, .arctic,
        .sakura, .void, .dune, .neonTokyo, .moss
    ]
}
