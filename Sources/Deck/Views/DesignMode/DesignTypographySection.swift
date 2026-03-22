import SwiftUI

struct DesignTypographySection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var fontSize: Double = 16
    @State private var fontWeight: String = "Regular"
    @State private var lineHeight: String = ""
    @State private var textAlign: String = "left"

    private let weights = ["Light", "Regular", "Medium", "Semibold", "Bold"]
    @State private var didSync = false

    var body: some View {
        inspectorSection(
            category: .typography,
            theme: theme,
            designMode: designMode
        ) {
            // Font size
            HStack(spacing: 0) {
                Text("Size")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Stepper(value: $fontSize, in: 8...96, step: 1) {
                    Text("\(Int(fontSize))px")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                }
            }
            .onChange(of: fontSize) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .typography,
                    property: "font-size",
                    value: "\(Int(newValue))px"
                ))
            }

            // Font weight
            HStack(spacing: 0) {
                Text("Weight")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $fontWeight) {
                    ForEach(weights, id: \.self) { weight in
                        Text(weight).tag(weight)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: fontWeight) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .typography,
                    property: "font-weight",
                    value: cssWeight(newValue)
                ))
            }

            // Line height
            InspectorField(label: "Line H", value: $lineHeight, placeholder: "1.5") {
                guard !lineHeight.isEmpty else { return }
                designMode.addChange(DesignChange(
                    category: .typography,
                    property: "line-height",
                    value: lineHeight
                ))
            }

            // Text alignment
            HStack(spacing: 0) {
                Text("Align")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $textAlign) {
                    Image(systemName: "text.alignleft").tag("left")
                    Image(systemName: "text.aligncenter").tag("center")
                    Image(systemName: "text.alignright").tag("right")
                    Image(systemName: "text.justify").tag("justify")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: textAlign) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .typography,
                    property: "text-align",
                    value: newValue
                ))
            }
        }
        .onChange(of: designMode.selectedElement?.selector) { _, _ in
            syncFromElement()
        }
        .onAppear { syncFromElement() }
    }

    private func syncFromElement() {
        guard let styles = designMode.selectedElement?.computedStyles, !didSync else { return }
        didSync = true
        if let size = styles["font-size"], let px = Double(size.replacingOccurrences(of: "px", with: "")) {
            fontSize = px
        }
        if let weight = styles["font-weight"] {
            fontWeight = cssWeightName(weight)
        }
        if let lh = styles["line-height"], lh != "normal" {
            lineHeight = lh
        }
        if let align = styles["text-align"] {
            textAlign = align
        }
    }

    private func cssWeightName(_ value: String) -> String {
        switch value {
        case "300": return "Light"
        case "400", "normal": return "Regular"
        case "500": return "Medium"
        case "600": return "Semibold"
        case "700", "bold": return "Bold"
        default: return "Regular"
        }
    }

    private func cssWeight(_ name: String) -> String {
        switch name {
        case "Light": return "300"
        case "Regular": return "400"
        case "Medium": return "500"
        case "Semibold": return "600"
        case "Bold": return "700"
        default: return "400"
        }
    }
}
