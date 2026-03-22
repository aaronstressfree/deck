import SwiftUI

struct TerminalSettingsView: View {
    @AppStorage("terminalFontFamily") private var fontFamily: String = "auto"
    @AppStorage("terminalFontSize") private var fontSize: Double = 12
    @AppStorage("terminalLineHeight") private var lineHeight: Double = 1.2
    @AppStorage("terminalCursorStyle") private var cursorStyle = "block"
    @AppStorage("terminalCursorBlink") private var cursorBlink = true
    @AppStorage("terminalScrollbackLimit") private var scrollbackLimit = 5000
    @AppStorage("terminalBellMode") private var bellMode = "visual"

    var body: some View {
        Form {
            Section("Font") {
                Picker("Font Family", selection: $fontFamily) {
                    Text("Auto (best available)").tag("auto")
                    Divider()
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font)
                            .font(.custom(font, size: 14))
                            .tag(font)
                    }
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $fontSize, in: 10...24, step: 1) {
                        Text("Font Size")
                    }
                    .frame(width: 200)
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 40)
                }

                HStack {
                    Text("Line Height")
                    Spacer()
                    Slider(value: $lineHeight, in: 1.0...2.0, step: 0.1) {
                        Text("Line Height")
                    }
                    .frame(width: 200)
                    Text(String(format: "%.1f", lineHeight))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 40)
                }
            }

            Section("Cursor") {
                Picker("Style", selection: $cursorStyle) {
                    Text("Block").tag("block")
                    Text("Underline").tag("underline")
                    Text("Bar").tag("bar")
                }
                .pickerStyle(.segmented)

                Toggle("Blink cursor", isOn: $cursorBlink)
            }

            Section("Scrollback") {
                HStack {
                    Text("Buffer size")
                    Spacer()
                    TextField("Lines", value: $scrollbackLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("lines")
                }
            }

            Section("Bell") {
                Picker("Bell Mode", selection: $bellMode) {
                    Text("Off").tag("off")
                    Text("Visual Flash").tag("visual")
                    Text("System Sound").tag("sound")
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Monospace fonts available on this system, in preference order
    private var availableFonts: [String] {
        let preferred = [
            "JetBrains Mono",
            "Fira Code",
            "Cascadia Code",
            "Monaspace Neon",
            "Menlo",
            "SF Mono",
            "Monaco",
            "Courier New",
        ]
        let installed = Set(NSFontManager.shared.availableFontFamilies)
        return preferred.filter { installed.contains($0) }
    }
}
