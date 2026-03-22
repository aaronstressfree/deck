import SwiftUI
import AppKit

/// A collapsed sidebar icon button that shows a popover tooltip on hover.
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
                    .fill(isActive ? theme.surfaces.selected.swiftUIColor : (isHovered ? theme.surfaces.hover.swiftUIColor : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .popover(isPresented: $isHovered, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.background)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private var statusText: String {
        if !session.isRunning {
            if let code = session.exitCode, code != 0 { return "Exited (\(code))" }
            return "Ready"
        }
        return session.agentStatus.label
    }
}
