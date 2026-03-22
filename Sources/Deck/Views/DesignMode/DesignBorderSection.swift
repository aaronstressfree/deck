import SwiftUI

struct DesignBorderSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var borderWidth: Double = 1
    @State private var borderRadius: Double = 0
    @State private var borderStyle: String = "solid"

    var body: some View {
        inspectorSection(
            category: .borders,
            theme: theme,
            designMode: designMode
        ) {
            // Border width
            HStack(spacing: 0) {
                Text("Width")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Stepper(value: $borderWidth, in: 0...20, step: 1) {
                    Text("\(Int(borderWidth))px")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                }
            }
            .onChange(of: borderWidth) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .borders,
                    property: "border-width",
                    value: "\(Int(newValue))px"
                ))
            }

            // Border radius
            HStack(spacing: 0) {
                Text("Radius")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Stepper(value: $borderRadius, in: 0...100, step: 1) {
                    Text("\(Int(borderRadius))px")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                }
            }
            .onChange(of: borderRadius) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .borders,
                    property: "border-radius",
                    value: "\(Int(newValue))px"
                ))
            }

            // Border style
            HStack(spacing: 0) {
                Text("Style")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $borderStyle) {
                    Text("solid").tag("solid")
                    Text("dashed").tag("dashed")
                    Text("dotted").tag("dotted")
                    Text("none").tag("none")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: borderStyle) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .borders,
                    property: "border-style",
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
        guard let styles = designMode.selectedElement?.computedStyles else { return }
        if let w = styles["border-top-width"], let px = Double(w.replacingOccurrences(of: "px", with: "")) {
            borderWidth = px
        }
        if let r = styles["border-radius"], let px = Double(r.replacingOccurrences(of: "px", with: "")) {
            borderRadius = px
        }
        if let s = styles["border-style"] { borderStyle = s }
    }
}
