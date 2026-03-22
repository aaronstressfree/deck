import SwiftUI

struct DesignShadowSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var selectedPreset: String = "none"

    private let presets: [(String, String)] = [
        ("none", "none"),
        ("sm", "0 1px 2px rgba(0,0,0,0.05)"),
        ("md", "0 4px 6px rgba(0,0,0,0.1)"),
        ("lg", "0 10px 15px rgba(0,0,0,0.1)"),
        ("xl", "0 20px 25px rgba(0,0,0,0.1)")
    ]

    var body: some View {
        inspectorSection(
            category: .shadows,
            theme: theme,
            designMode: designMode
        ) {
            HStack(spacing: 4) {
                ForEach(presets, id: \.0) { preset in
                    Button(action: {
                        selectedPreset = preset.0
                        designMode.addChange(DesignChange(
                            category: .shadows,
                            property: "box-shadow",
                            value: preset.1
                        ))
                    }) {
                        Text(preset.0)
                            .font(.system(size: 11, weight: selectedPreset == preset.0 ? .semibold : .regular))
                            .foregroundStyle(selectedPreset == preset.0 ? theme.accent.primary.swiftUIColor : theme.text.tertiary.swiftUIColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(selectedPreset == preset.0 ? theme.accent.muted.swiftUIColor : theme.surfaces.inset.swiftUIColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
