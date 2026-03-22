import SwiftUI

/// A collapsed sidebar icon button that shows an instant tooltip to the right on hover.
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
                    .fill(isActive ? theme.surfaces.selected.swiftUIColor : Color.clear)
            )
        }
        .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
        .onHover { isHovered = $0 }
        .overlay(alignment: .leading) {
            if isHovered {
                Text(session.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.surfaces.elevated.swiftUIColor)
                            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    )
                    .fixedSize()
                    .offset(x: 40)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}
