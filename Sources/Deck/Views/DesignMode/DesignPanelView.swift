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
        HStack(spacing: 8) {
            if let el = designMode.selectedElement {
                Text("<\(el.tagName)>")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.accent.muted.swiftUIColor)
                    .cornerRadius(4)
                Text(el.selector)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                Text("Select an element")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
            }
            Spacer()
            Button(action: { designMode.deselectElement() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.surfaces.elevated.swiftUIColor)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(theme.borders.subtle.swiftUIColor)
            .frame(height: 1)
    }
}
