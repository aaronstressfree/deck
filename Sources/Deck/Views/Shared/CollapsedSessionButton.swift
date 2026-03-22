import SwiftUI
import AppKit

/// A collapsed sidebar icon button that shows a floating tooltip to the right on hover.
/// Uses NSWindow for the tooltip so it renders above all other views without clipping.
struct CollapsedSessionButton<Icon: View>: View {
    let session: Session
    let isActive: Bool
    let theme: Theme
    let onSelect: () -> Void
    @ViewBuilder let icon: Icon

    @State private var isHovered = false
    @State private var tooltipWindow: NSWindow?
    @State private var buttonFrame: CGRect = .zero

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
        .background(GeometryReader { geo in
            Color.clear.preference(key: FramePreferenceKey.self, value: geo.frame(in: .global))
        })
        .onPreferenceChange(FramePreferenceKey.self) { buttonFrame = $0 }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                showTooltip()
            } else {
                hideTooltip()
            }
        }
    }

    private func showTooltip() {
        hideTooltip()

        guard let screen = NSApp.keyWindow?.screen ?? NSScreen.main else { return }

        let label = session.displayName
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        let size = (label as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 20
        let height: CGFloat = 28
        let width = size.width + padding

        // Position to the right of the button, vertically centered
        let screenFrame = screen.frame
        let x = buttonFrame.maxX + 6
        // Convert from SwiftUI coordinates (top-left origin) to screen (bottom-left origin)
        let y = screenFrame.height - buttonFrame.midY - (height / 2)

        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.hasShadow = true

        let hostView = NSHostingView(rootView:
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.text.primary.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surfaces.elevated.swiftUIColor)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                )
        )
        window.contentView = hostView
        window.orderFront(nil)

        // Fade in
        window.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            window.animator().alphaValue = 1
        }

        tooltipWindow = window
    }

    private func hideTooltip() {
        guard let window = tooltipWindow else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.08
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
        tooltipWindow = nil
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
