import SwiftUI

/// A plain button style that shows a subtle background on hover.
/// Use for inline/icon buttons that need visible hover feedback.
struct HoverButtonStyle: ButtonStyle {
    let hoverColor: Color
    let cornerRadius: CGFloat

    @State private var isHovered = false

    init(hoverColor: Color, cornerRadius: CGFloat = 4) {
        self.hoverColor = hoverColor
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(configuration.isPressed ? hoverColor.opacity(1.5) : (isHovered ? hoverColor : Color.clear))
            )
            .onHover { isHovered = $0 }
    }
}
