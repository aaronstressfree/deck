import SwiftUI

struct DesignPreviewSheet: View {
    @Environment(\.deckTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var designMode: DesignModeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Instruction Preview")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            // Markdown preview
            ScrollView {
                Text(designMode.toMarkdown())
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(theme.surfaces.primary.swiftUIColor)
            .cornerRadius(6)
            .padding(.horizontal, 16)

            // Actions
            HStack {
                Spacer()
                Button("Copy") {
                    designMode.copyToClipboard()
                    dismiss()
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 500, height: 400)
        .background(theme.surfaces.elevated.swiftUIColor)
    }
}
