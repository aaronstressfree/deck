import SwiftUI

/// Generates a daily summary of work done across all sessions.
struct DailyDigestView: View {
    @Environment(\.deckTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var digest: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Daily Digest")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(digest, forType: .string)
                }
                .disabled(digest.isEmpty)
                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            if digest.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No activity recorded today")
                        .foregroundStyle(.secondary)
                    Text("Use Deck sessions to track your work")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    Text(digest)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear { generateDigest() }
    }

    private func generateDigest() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let today = dateFormatter.string(from: Date())

        digest = """
        # Daily Digest — \(today)

        ## Sessions
        No sessions recorded yet.

        ## Summary
        Start using Deck to track your daily work.
        Digests are generated from session activity.
        """
    }
}
