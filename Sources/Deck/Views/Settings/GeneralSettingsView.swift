import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("defaultShell") private var defaultShell = "/bin/zsh"
    @AppStorage("defaultWorkingDirectory") private var defaultWorkingDirectory = ""
    @AppStorage("restoreSessionsOnLaunch") private var restoreOnLaunch = true
    @AppStorage("showStatusBar") private var showStatusBar = true
    @AppStorage("anthropicApiKey") private var customApiKey = ""

    var body: some View {
        Form {
            Section("Shell") {
                Picker("Default Shell", selection: $defaultShell) {
                    Text("/bin/zsh").tag("/bin/zsh")
                    Text("/bin/bash").tag("/bin/bash")
                }

                HStack {
                    TextField("Default Working Directory", text: $defaultWorkingDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            defaultWorkingDirectory = url.path
                        }
                    }
                }
            }

            Section("Behavior") {
                Toggle("Restore sessions on launch", isOn: $restoreOnLaunch)
                Toggle("Show status bar", isOn: $showStatusBar)
            }

            Section("AI") {
                SecureField("Anthropic API Key", text: $customApiKey)
                    .textFieldStyle(.roundedBorder)
                if customApiKey.isEmpty {
                    Text("Using built-in key. Set your own to use your account.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Using your custom API key.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
