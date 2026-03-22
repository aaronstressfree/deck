import SwiftUI
import AppKit

/// A collapsed sidebar icon button that shows a tooltip with arrow to the right on hover.
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
        let textSize = (label as NSString).size(withAttributes: [.font: font])
        let hPad: CGFloat = 20
        let vPad: CGFloat = 10
        let arrowWidth: CGFloat = 7
        let bubbleWidth = textSize.width + hPad
        let bubbleHeight = textSize.height + vPad
        let totalWidth = bubbleWidth + arrowWidth
        let totalHeight = max(bubbleHeight, 28)

        // Convert button frame from SwiftUI global coords to screen coords
        // SwiftUI global = relative to window content, y-down
        // Screen coords = absolute, y-up from bottom
        guard let windowFrame = NSApp.keyWindow?.frame else { return }
        let x = windowFrame.minX + buttonFrame.maxX + 4
        let y = windowFrame.maxY - buttonFrame.midY - (totalHeight / 2)

        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: totalWidth, height: totalHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.hasShadow = false

        let tooltipView = TooltipView(
            frame: NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight),
            text: label,
            font: font,
            arrowWidth: arrowWidth,
            bgColor: theme.surfaces.elevated.nsColor,
            textColor: theme.text.primary.nsColor
        )
        window.contentView = tooltipView
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

/// Custom NSView that draws a tooltip bubble with a left-pointing arrow.
private class TooltipView: NSView {
    let text: String
    let font: NSFont
    let arrowWidth: CGFloat
    let bgColor: NSColor
    let textColor: NSColor

    init(frame: NSRect, text: String, font: NSFont, arrowWidth: CGFloat, bgColor: NSColor, textColor: NSColor) {
        self.text = text
        self.font = font
        self.arrowWidth = arrowWidth
        self.bgColor = bgColor
        self.textColor = textColor
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds
        let cornerRadius: CGFloat = 7
        let arrowH: CGFloat = 10  // arrow height (half)
        let midY = bounds.midY

        // Bubble rect (right of arrow)
        let bubbleRect = NSRect(
            x: arrowWidth,
            y: 0,
            width: bounds.width - arrowWidth,
            height: bounds.height
        )

        // Build path: rounded rect with left-pointing arrow
        let path = CGMutablePath()

        // Start at top-left of bubble (after corner)
        path.move(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY))

        // Top edge
        path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY))
        // Top-right corner
        path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius),
                     radius: cornerRadius, startAngle: .pi / 2, endAngle: 0, clockwise: true)
        // Right edge
        path.addLine(to: CGPoint(x: bubbleRect.maxX, y: cornerRadius))
        // Bottom-right corner
        path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: cornerRadius),
                     radius: cornerRadius, startAngle: 0, endAngle: -.pi / 2, clockwise: true)
        // Bottom edge
        path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY))
        // Bottom-left corner
        path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: cornerRadius),
                     radius: cornerRadius, startAngle: -.pi / 2, endAngle: .pi, clockwise: true)
        // Left edge down to arrow
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: midY + arrowH))
        // Arrow point
        path.addLine(to: CGPoint(x: 0, y: midY))
        // Arrow back
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: midY - arrowH))
        // Left edge up to top-left corner
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY - cornerRadius))
        // Top-left corner
        path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius),
                     radius: cornerRadius, startAngle: .pi, endAngle: .pi / 2, clockwise: true)

        path.closeSubpath()

        // Shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 8, color: NSColor.black.withAlphaComponent(0.3).cgColor)
        ctx.setFillColor(bgColor.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()

        // Fill again without shadow (for crisp edges)
        ctx.setFillColor(bgColor.cgColor)
        ctx.addPath(path)
        ctx.fillPath()

        // Border
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
        ctx.setLineWidth(0.5)
        ctx.addPath(path)
        ctx.strokePath()

        // Text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
        ]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let textOrigin = NSPoint(
            x: arrowWidth + (bubbleRect.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2
        )
        (text as NSString).draw(at: textOrigin, withAttributes: attrs)
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
