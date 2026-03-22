import SwiftUI
import AppKit

/// A collapsed sidebar icon button that shows a popover tooltip to the right on hover.
struct CollapsedSessionButton<Icon: View>: View {
    let session: Session
    let isActive: Bool
    let theme: Theme
    let onSelect: () -> Void
    @ViewBuilder let icon: Icon

    @State private var isHovered = false
    @State private var popover: NSPopover?

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
        .overlay(
            // Invisible anchor view for the popover
            TooltipAnchor(
                text: session.displayName,
                session: session,
                isHovered: $isHovered,
                popover: $popover
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// NSViewRepresentable that manages an NSPopover tooltip anchored to this view.
private struct TooltipAnchor: NSViewRepresentable {
    let text: String
    let session: Session
    @Binding var isHovered: Bool
    @Binding var popover: NSPopover?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.anchorView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.text = text
        if isHovered && popover == nil {
            // Show after tiny delay to avoid flicker
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard self.isHovered else { return }
                context.coordinator.showPopover()
            }
        } else if !isHovered && popover != nil {
            context.coordinator.hidePopover()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: TooltipAnchor
        weak var anchorView: NSView?
        var text: String = ""

        init(parent: TooltipAnchor) {
            self.parent = parent
        }

        func showPopover() {
            guard let anchor = anchorView, anchor.window != nil else { return }
            guard parent.popover == nil else { return }

            // Session name
            let nameLabel = NSTextField(labelWithString: text)
            nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            nameLabel.textColor = .white
            nameLabel.backgroundColor = .clear
            nameLabel.isBordered = false
            nameLabel.isEditable = false
            nameLabel.sizeToFit()

            // Status line
            let status = parent.session.isRunning
                ? parent.session.agentStatus.label
                : (parent.session.exitCode != nil && parent.session.exitCode != 0 ? "Exited" : "Ready")
            let statusLabel = NSTextField(labelWithString: status)
            statusLabel.font = .systemFont(ofSize: 11, weight: .regular)
            statusLabel.textColor = NSColor.white.withAlphaComponent(0.5)
            statusLabel.backgroundColor = .clear
            statusLabel.isBordered = false
            statusLabel.isEditable = false
            statusLabel.sizeToFit()

            let hPad: CGFloat = 14
            let vPad: CGFloat = 10
            let width = max(nameLabel.frame.width, statusLabel.frame.width) + hPad * 2
            let height = nameLabel.frame.height + statusLabel.frame.height + 4 + vPad * 2

            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
            statusLabel.frame.origin = NSPoint(x: hPad, y: vPad)
            nameLabel.frame.origin = NSPoint(x: hPad, y: vPad + statusLabel.frame.height + 4)
            contentView.addSubview(nameLabel)
            contentView.addSubview(statusLabel)

            let vc = NSViewController()
            vc.view = contentView

            let pop = NSPopover()
            pop.contentViewController = vc
            pop.behavior = .semitransient
            pop.animates = true
            // Dark appearance for modern look
            pop.appearance = NSAppearance(named: .darkAqua)

            // Show with offset — use a wider rect to push it further right
            let offsetRect = NSRect(x: anchor.bounds.maxX + 8, y: 0, width: 1, height: anchor.bounds.height)
            pop.show(relativeTo: offsetRect, of: anchor, preferredEdge: .maxX)

            parent.popover = pop
        }

        func hidePopover() {
            parent.popover?.performClose(nil)
            parent.popover = nil
        }
    }
}
