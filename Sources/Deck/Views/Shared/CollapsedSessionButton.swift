import SwiftUI

/// A collapsed sidebar icon button with hover highlight and native tooltip.
struct CollapsedSessionButton<Icon: View>: View {
    let session: Session
    let isActive: Bool
    let theme: Theme
    let onSelect: () -> Void
    @ViewBuilder let icon: Icon

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                icon

                if session.isRunning && session.agentStatus.isActive {
                    Circle()
                        .fill(theme.accent.primary.swiftUIColor)
                        .frame(width: 5, height: 5)
                        .offset(x: 8, y: -8)
                        .opacity(0.8)
                }
            }
            .frame(width: 32, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? theme.surfaces.selected.swiftUIColor
                          : (isHovered ? theme.surfaces.hover.swiftUIColor : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(session.displayName)
    }
}
