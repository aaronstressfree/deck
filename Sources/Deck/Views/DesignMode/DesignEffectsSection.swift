import SwiftUI

struct DesignEffectsSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var opacity: Double = 100

    var body: some View {
        inspectorSection(
            category: .effects,
            theme: theme,
            designMode: designMode
        ) {
            HStack(spacing: 0) {
                Text("Opacity")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Slider(value: $opacity, in: 0...100, step: 1)
                Text("\(Int(opacity))%")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 32, alignment: .trailing)
            }
            .onChange(of: opacity) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .effects,
                    property: "opacity",
                    value: String(format: "%.2f", newValue / 100)
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
        if let o = styles["opacity"], let val = Double(o) {
            opacity = val * 100
        }
    }
}
