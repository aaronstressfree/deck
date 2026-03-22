import SwiftUI

/// Overlays a Figma design frame on top of the browser preview for comparison.
struct FigmaOverlayView: View {
    @Environment(\.deckTheme) private var theme
    @Binding var isVisible: Bool
    @Binding var opacity: Double
    @State private var figmaUrl: String = ""
    @State private var overlayImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                Image(systemName: "paintbrush.pointed")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)

                TextField("Figma frame URL...", text: $figmaUrl)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.surfaces.inset.swiftUIColor)
                    )

                // Opacity slider
                HStack(spacing: 4) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    Slider(value: $opacity, in: 0...1)
                        .frame(width: 80)
                    Text("\(Int(opacity * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                        .frame(width: 30)
                }

                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(theme.surfaces.elevated.swiftUIColor.opacity(0.95))
        }
    }
}
