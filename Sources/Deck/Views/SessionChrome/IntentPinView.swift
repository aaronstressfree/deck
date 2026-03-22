import SwiftUI

/// Session context panel — a collapsible area where the user writes persistent context
/// that gets injected into Claude/Amp's instructions. Replaces the old "intent pin."
///
/// UX: Click "Context" in the toolbar → panel slides down with a text area.
/// Whatever you type here is saved per-session and written to CLAUDE.md.
/// Examples: "Build a mortgage form matching the Figma at [link]"
///           "Use Market components, dark theme, mobile-first"
///           "This is for the seller onboarding flow, ticket LIN-1234"
struct SessionContextView: View {
    @Environment(\.deckTheme) private var theme
    @Binding var contextText: String?
    @Binding var isExpanded: Bool
    let agentType: AgentType

    @State private var editText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        if isExpanded {
            expandedView
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accent.primary.swiftUIColor)
                Text("Session Context")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                Text("— visible to \(agentType.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                Spacer()
                Button(action: {
                    // Save and close
                    contextText = editText.isEmpty ? nil : editText
                    withAnimation(.easeOut(duration: 0.15)) { isExpanded = false }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                }
                .buttonStyle(.plain)
            }

            // Text area
            TextEditor(text: $editText)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(theme.text.primary.swiftUIColor)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: 48, maxHeight: 120)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surfaces.inset.swiftUIColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isFocused ? theme.borders.focused.swiftUIColor : theme.borders.subtle.swiftUIColor, lineWidth: 1)
                        )
                )

            // Hint
            Text("This text is injected into \(agentType.displayName)'s context. Use it for goals, design links, constraints.")
                .font(.system(size: 12))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.surfaces.elevated.swiftUIColor)
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(theme.borders.subtle.swiftUIColor),
            alignment: .bottom
        )
        .onAppear {
            editText = contextText ?? ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isFocused = true }
        }
        .onChange(of: editText) { _, newValue in
            // Auto-save as you type
            contextText = newValue.isEmpty ? nil : newValue
        }
    }
}
