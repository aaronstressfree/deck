import SwiftUI

struct DesignPanelView: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader

            Divider()
                .background(theme.borders.primary.swiftUIColor)

            // Scrollable sections
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    DesignColorSection()
                    sectionDivider
                    DesignTypographySection()
                    sectionDivider
                    DesignSpacingSection()
                    sectionDivider
                    DesignLayoutSection()
                    sectionDivider
                    DesignSizingSection()
                    sectionDivider
                    DesignBorderSection()
                    sectionDivider
                    DesignShadowSection()
                    sectionDivider
                    DesignEffectsSection()
                }
            }

            // Changes list (if any)
            if designMode.hasChanges {
                Divider()
                    .background(theme.borders.primary.swiftUIColor)
                DesignChangesList()
            }

            // Send footer
            Divider()
                .background(theme.borders.primary.swiftUIColor)
            DesignSendFooter()
        }
        .background(theme.surfaces.elevated.swiftUIColor)
        .onChange(of: sessionManager.activeSessionId) { _, _ in
            designMode.syncWithBrowser(session: sessionManager.activeSession)
        }
        .onAppear {
            designMode.syncWithBrowser(session: sessionManager.activeSession)
        }
    }

    private var panelHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let el = designMode.selectedElement {
                    // Element tag badge
                    Text("<\(el.tagName)>")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.accent.primary.swiftUIColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.accent.muted.swiftUIColor)
                        .cornerRadius(4)

                    Text(el.selector)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.text.secondary.swiftUIColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Image(systemName: "rectangle.and.hand.point.up.left.filled")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.accent.primary.swiftUIColor)
                    Text("Select an element")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.text.secondary.swiftUIColor)
                }
                Spacer()
                Button(action: { designMode.deselectElement() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                }
                .buttonStyle(.plain)
            }

            // Show element classes if present
            if let el = designMode.selectedElement, !el.className.isEmpty {
                Text(".\(el.className.split(separator: " ").joined(separator: " ."))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.surfaces.elevated.swiftUIColor)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(theme.borders.subtle.swiftUIColor)
            .frame(height: 1)
    }
}
