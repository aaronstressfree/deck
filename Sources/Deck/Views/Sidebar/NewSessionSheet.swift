import SwiftUI

struct NewSessionSheet: View {
    @Environment(\.deckTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let onCreate: (AgentType, String, UUID?, String?) -> Void
    let groups: [SessionGroup]
    let activeProjectId: UUID?

    @State private var agentType: AgentType = .claude
    @State private var name: String = ""
    @State private var workingDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path
    @State private var selectedGroupId: UUID?

    var body: some View {
        VStack(spacing: 20) {
            Text("New Session")
                .font(.system(size: 18, weight: .semibold))

            // Agent type selector
            HStack(spacing: 8) {
                ForEach(AgentType.allCases, id: \.self) { type in
                    agentTypeButton(type)
                }
            }

            Form {
                TextField("Name (optional)", text: $name)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    TextField("Working Directory", text: $workingDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            workingDirectory = url.path
                        }
                    }
                }

                // Project picker — always shown, defaults to active project
                Picker("Project", selection: $selectedGroupId) {
                    ForEach(groups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(agentType == .claude ? "Start Claude" : agentType == .amp ? "Start Amp" : "Open Shell") {
                    onCreate(agentType, workingDirectory, selectedGroupId, name.isEmpty ? nil : name)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            // Default to active project
            selectedGroupId = activeProjectId ?? groups.first?.id
            // Set working directory from selected project
            if let project = groups.first(where: { $0.id == selectedGroupId }),
               let dir = project.workingDirectory {
                workingDirectory = dir
            }
        }
    }

    private func agentTypeButton(_ type: AgentType) -> some View {
        Button(action: { agentType = type }) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 22))
                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(width: 90, height: 65)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(agentType == type ? Color.accentColor.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(agentType == type ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
