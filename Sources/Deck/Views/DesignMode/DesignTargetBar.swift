import SwiftUI

/// Legacy target bar — no longer used in the main panel layout.
/// Kept as a minimal note field for potential future use.
struct DesignTargetBar: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "scope")
                .font(.system(size: 11))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
            TextField("Target element", text: $designMode.instructionSet.target)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(theme.surfaces.inset.swiftUIColor)
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
