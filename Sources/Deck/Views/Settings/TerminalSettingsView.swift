import SwiftUI

struct TerminalSettingsView: View {
    @AppStorage("terminalFontSize") private var fontSize: Double = 13
    @AppStorage("terminalLineHeight") private var lineHeight: Double = 1.2
    @AppStorage("terminalCursorStyle") private var cursorStyle = "block"
    @AppStorage("terminalCursorBlink") private var cursorBlink = true
    @AppStorage("terminalScrollbackLimit") private var scrollbackLimit = 5000
    @AppStorage("terminalBellMode") private var bellMode = "visual"

    var body: some View {
        Form {
            Section("Font") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $fontSize, in: 8...24, step: 1) {
                        Text("Font Size")
                    }
                    .frame(width: 200)
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 12, design: .monospaced))
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
}
