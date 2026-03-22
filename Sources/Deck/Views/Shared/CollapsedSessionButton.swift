import SwiftUI
import AppKit

/// A collapsed sidebar icon button with instant tooltip that doesn't block clicks.
struct CollapsedSessionButton<Icon: View>: View {
    let session: Session
    let isActive: Bool
    let theme: Theme
    let onSelect: () -> Void
    @ViewBuilder let icon: Icon

    @State private var isHovered = false
    @State private var tooltipWindow: NSWindow?

    var body: some View {
        Button(action: {
            hideTooltip()
            onSelect()
        }) {
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
        .background(GeometryReader { geo in
            Color.clear.preference(key: FrameKey.self, value: geo.frame(in: .global))
        })
        .onPreferenceChange(FrameKey.self) { frame = $0 }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                showTooltip()
            } else {
                hideTooltip()
            }
        }
    }

    @State private var frame: CGRect = .zero

    private func showTooltip() {
        hideTooltip()
        guard let wf = NSApp.keyWindow?.frame else { return }

        let name = session.displayName
        let status = statusText
        let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let statusFont = NSFont.systemFont(ofSize: 10, weight: .regular)

        let nameSize = (name as NSString).size(withAttributes: [.font: font])
        let statusSize = (status as NSString).size(withAttributes: [.font: statusFont])

        let pad: CGFloat = 10
        let w = max(nameSize.width, statusSize.width) + pad * 2
        let h = nameSize.height + statusSize.height + 4 + pad * 2

        let x = wf.minX + frame.maxX + 8
        let y = wf.maxY - frame.midY - h / 2

        let win = NSWindow(contentRect: NSRect(x: x, y: y, width: w, height: h),
                           styleMask: .borderless, backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.hasShadow = true

        let v = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        v.wantsLayer = true
        v.layer?.cornerRadius = 6
        v.layer?.backgroundColor = theme.surfaces.elevated.nsColor.cgColor
        v.layer?.borderColor = NSColor.white.withAlphaComponent(0.06).cgColor
        v.layer?.borderWidth = 0.5
        v.layer?.shadowColor = NSColor.black.cgColor
        v.layer?.shadowOpacity = 0.3
        v.layer?.shadowRadius = 8
        v.layer?.shadowOffset = CGSize(width: 0, height: -2)

        let nameField = NSTextField(labelWithString: name)
        nameField.font = font
        nameField.textColor = theme.text.primary.nsColor
        nameField.sizeToFit()
        nameField.frame.origin = NSPoint(x: pad, y: pad + statusSize.height + 4)

        let statusField = NSTextField(labelWithString: status)
        statusField.font = statusFont
        statusField.textColor = theme.text.quaternary.nsColor
        statusField.sizeToFit()
        statusField.frame.origin = NSPoint(x: pad, y: pad)

        v.addSubview(nameField)
        v.addSubview(statusField)
        win.contentView = v

        win.alphaValue = 0
        win.orderFront(nil)
        NSAnimationContext.runAnimationGroup { $0.duration = 0.1; win.animator().alphaValue = 1 }
        tooltipWindow = win
    }

    private func hideTooltip() {
        if let win = tooltipWindow {
            win.orderOut(nil)
            tooltipWindow = nil
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

private struct FrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
