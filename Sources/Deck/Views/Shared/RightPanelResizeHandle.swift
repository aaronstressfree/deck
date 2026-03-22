import SwiftUI

/// A draggable handle for resizing a right-side panel.
/// Mirrors SidebarResizeHandle but drags in the opposite direction.
struct RightPanelResizeHandle: View {
    @Environment(\.deckTheme) private var theme
    @Binding var width: Double
    let minWidth: Double
    let maxWidth: Double

    @State private var isDragging = false
    @State private var isHovered = false
    @State private var startWidth: Double = 0

    var body: some View {
        Rectangle()
            .fill(isDragging ? theme.accent.primary.swiftUIColor : (isHovered ? theme.borders.hover.swiftUIColor : theme.borders.primary.swiftUIColor))
            .frame(width: isDragging ? 2 : 1)
            .contentShape(Rectangle().inset(by: -3))
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startWidth = width
                        }
                        // Dragging left increases width (opposite of sidebar)
                        let newWidth = startWidth - value.translation.width
                        width = max(minWidth, min(maxWidth, newWidth))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}
