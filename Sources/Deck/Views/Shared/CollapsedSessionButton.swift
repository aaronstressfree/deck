import SwiftUI

/// Collapsed sidebar icon with hover tooltip that doesn't block clicks.
struct CollapsedSessionButton<Icon: View>: View {
    let session: Session
    let isActive: Bool
    let theme: Theme
    let onSelect: () -> Void
    @ViewBuilder let icon: Icon

    @State private var isHovered = false
    @State private var showTooltip = false

    var body: some View {
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
        .frame(width: 36, height: 30)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? theme.surfaces.selected.swiftUIColor
                      : (isHovered ? theme.surfaces.hover.swiftUIColor : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showTooltip = false
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                // Small delay so tooltip doesn't flash on quick mouse-through
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if isHovered { showTooltip = true }
                }
            } else {
                showTooltip = false
            }
        }
        .popover(isPresented: $showTooltip, arrowEdge: .trailing) {
            Text(session.displayName)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .fixedSize()
        }
    }
}
