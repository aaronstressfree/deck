import SwiftUI
import AppKit

/// A collapsed sidebar icon button that shows a floating tooltip to the right on hover.
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
        let hPad: CGFloat = 16
        let vPad: CGFloat = 8
        let width = size.width + hPad
        let height = size.height + vPad

        // Position to the right of the button
        let x = buttonFrame.maxX + 6
        let y = screen.frame.height - buttonFrame.midY - (height / 2)

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

        // Use a simple NSVisualEffectView + NSTextField (no SwiftUI hosting)
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let bg = NSVisualEffectView(frame: container.bounds)
        bg.material = .popover
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 6
        bg.layer?.masksToBounds = true
        container.addSubview(bg)

        let textField = NSTextField(labelWithString: label)
        textField.font = font
        textField.textColor = .labelColor
        textField.sizeToFit()
        textField.frame.origin = NSPoint(
            x: (width - textField.frame.width) / 2,
            y: (height - textField.frame.height) / 2
        )
        container.addSubview(textField)

        window.contentView = container
        window.orderFront(nil)

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
