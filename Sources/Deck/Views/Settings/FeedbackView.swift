import SwiftUI

/// Feedback view — lets users submit bugs or feature requests as GitHub issues.
/// Uses GitHub's issue URL scheme (no API key required).
struct FeedbackView: View {
    private static let repoURL = "https://github.com/aaronstressfree/deck"

    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case other = "Other"

        var label: String { "[\(rawValue)]" }
        var icon: String {
            switch self {
            case .bug: return "ladybug"
            case .feature: return "lightbulb"
            case .other: return "bubble.left"
            }
        }
    }

    @State private var feedbackType: FeedbackType = .bug
    @State private var title = ""
    @State private var description = ""
    @State private var includeSystemInfo = true
    @State private var submitted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Send Feedback")
                .font(.system(size: 18, weight: .semibold))

            Text("Submit a bug report or feature request. This opens a GitHub issue on the Deck repository.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Type selector
            HStack(spacing: 8) {
                ForEach(FeedbackType.allCases, id: \.self) { type in
                    Button(action: { feedbackType = type }) {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            Text(type.rawValue)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(feedbackType == type ? Color.accentColor.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(feedbackType == type ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Brief summary of the issue", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
            }

            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextEditor(text: $description)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 120, maxHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    )
            }

            // System info toggle
            Toggle(isOn: $includeSystemInfo) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include system info")
                        .font(.system(size: 14))
                    Text("macOS version, Deck version, session count")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Actions
            HStack {
                // Link to existing issues
                Button(action: {
                    if let url = URL(string: "\(Self.repoURL)/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("View Existing Issues")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                if submitted {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Opened in browser")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: submitFeedback) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                            Text("Open GitHub Issue")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty)
                }
            }
        }
        .padding(24)
    }

    private func submitFeedback() {
        var body = description

        if includeSystemInfo {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let macOS = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

            body += "\n\n---\n**System Info**\n"
            body += "- macOS: \(macOS)\n"
            body += "- Deck: \(appVersion)\n"
            body += "- Swift: \(swiftVersion)\n"
        }

        // Build GitHub new issue URL with pre-filled fields
        let issueTitle = "\(feedbackType.label) \(title)"
        var components = URLComponents(string: "\(Self.repoURL)/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "title", value: issueTitle),
            URLQueryItem(name: "body", value: body),
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
            submitted = true

            // Reset after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                submitted = false
            }
        }
    }

    private var swiftVersion: String {
        #if swift(>=6.0)
        return "6.0+"
        #elseif swift(>=5.9)
        return "5.9+"
        #else
        return "5.x"
        #endif
    }
}
