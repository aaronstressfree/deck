import SwiftUI

// MARK: - Shared input helper

struct InspectorField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    var onCommit: () -> Void = {}
    @Environment(\.deckTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
                .frame(width: 54, alignment: .leading)
            TextField(placeholder, text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(theme.surfaces.inset.swiftUIColor)
                .cornerRadius(4)
                .onSubmit { onCommit() }
        }
    }
}

// MARK: - Color Section

struct DesignColorSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var bgColor: Color = .clear
    @State private var textColor: Color = .white
    @State private var borderColor: Color = .gray
    @State private var accentColor: Color = .blue

    @State private var bgHex: String = ""
    @State private var textHex: String = ""
    @State private var borderHex: String = ""
    @State private var accentHex: String = ""

    var body: some View {
        inspectorSection(
            category: .color,
            theme: theme,
            designMode: designMode
        ) {
            colorRow(label: "BG", color: $bgColor, hex: $bgHex, property: "background-color")
            colorRow(label: "Text", color: $textColor, hex: $textHex, property: "color")
            colorRow(label: "Border", color: $borderColor, hex: $borderHex, property: "border-color")
            colorRow(label: "Accent", color: $accentColor, hex: $accentHex, property: "accent-color")
        }
    }

    private func colorRow(label: String, color: Binding<Color>, hex: Binding<String>, property: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
                .frame(width: 54, alignment: .leading)

            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 24, height: 20)

            TextField("#hex", text: hex)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.text.primary.swiftUIColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(theme.surfaces.inset.swiftUIColor)
                .cornerRadius(4)
                .padding(.leading, 6)
                .onSubmit {
                    let value = hex.wrappedValue.isEmpty ? colorToHex(color.wrappedValue) : hex.wrappedValue
                    guard !value.isEmpty else { return }
                    designMode.addChange(DesignChange(
                        category: .color,
                        property: property,
                        value: value
                    ))
                }
        }
    }

    private func colorToHex(_ color: Color) -> String {
        guard let nsColor = NSColor(color).usingColorSpace(.sRGB) else { return "" }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Shared section wrapper

@MainActor
func inspectorSection<Content: View>(
    category: DesignCategory,
    theme: Theme,
    designMode: DesignModeManager,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    VStack(spacing: 0) {
        Button(action: { withAnimation(.easeOut(duration: 0.15)) { designMode.toggleSection(category) } }) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .frame(width: 14)
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .rotationEffect(.degrees(designMode.isSectionExpanded(category) ? 90 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if designMode.isSectionExpanded(category) {
            VStack(spacing: 6) {
                content()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
}
