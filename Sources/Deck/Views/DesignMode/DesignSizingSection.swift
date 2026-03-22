import SwiftUI

struct DesignSizingSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var width: String = ""
    @State private var height: String = ""

    var body: some View {
        inspectorSection(
            category: .sizing,
            theme: theme,
            designMode: designMode
        ) {
            HStack(spacing: 6) {
                // Width
                HStack(spacing: 0) {
                    Text("W")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                        .frame(width: 16, alignment: .leading)
                    TextField("auto", text: $width)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(theme.surfaces.inset.swiftUIColor)
                        .cornerRadius(4)
                        .onSubmit { commitSize("width", width) }
                }

                // Height
                HStack(spacing: 0) {
                    Text("H")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                        .frame(width: 16, alignment: .leading)
                    TextField("auto", text: $height)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(theme.surfaces.inset.swiftUIColor)
                        .cornerRadius(4)
                        .onSubmit { commitSize("height", height) }
                }
            }
        }
        .onChange(of: designMode.selectedElement?.selector) { _, _ in
            syncFromElement()
        }
        .onAppear { syncFromElement() }
    }

    private func syncFromElement() {
        guard let styles = designMode.selectedElement?.computedStyles else { return }
        if let w = styles["width"] { width = w }
        if let h = styles["height"] { height = h }
    }

    private func commitSize(_ property: String, _ value: String) {
        guard !value.isEmpty else { return }
        let formatted = value.hasSuffix("px") || value.hasSuffix("rem") || value.hasSuffix("%") || value.hasSuffix("vw") || value.hasSuffix("vh") || value == "auto" ? value : "\(value)px"
        designMode.addChange(DesignChange(
            category: .sizing,
            property: property,
            value: formatted
        ))
    }
}
