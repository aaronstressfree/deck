import Foundation
import AppKit

/// Checks GitHub for newer releases and reports availability.
/// Checks at most once per day to avoid spamming the API.
@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateAvailable: Bool = false
    @Published var isInstalling: Bool = false
    @Published var readyToRelaunch: Bool = false
    @Published var latestVersion: String = ""

    private static let repo = "aaronstressfree/deck"
    private static let lastCheckKey = "lastUpdateCheck"
    private static let checkIntervalSeconds: TimeInterval = 86400 // 24 hours

    /// The current app build number from the bundle
    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    /// Check for updates if we haven't checked recently
    func checkIfNeeded() {
        let lastCheck = UserDefaults.standard.double(forKey: Self.lastCheckKey)
        let now = Date().timeIntervalSince1970
        guard now - lastCheck > Self.checkIntervalSeconds else { return }

        Task {
            await check()
        }
    }

    /// Force a check right now
    func check() async {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastCheckKey)

        guard let url = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/tags/latest") else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            // Parse build number from release body (e.g. "Build 42.")
            if let body = json["body"] as? String,
               let range = body.range(of: #"Build (\d+)"#, options: .regularExpression) {
                let match = body[range]
                let buildStr = match.replacingOccurrences(of: "Build ", with: "").replacingOccurrences(of: ".", with: "")
                if let remoteBuild = Int(buildStr), let localBuild = Int(currentBuild), remoteBuild > localBuild {
                    latestVersion = json["name"] as? String ?? "New version"
                    updateAvailable = true
                    NSLog("[DECK] Update available: build \(remoteBuild) > \(localBuild)")
                }
            }
        } catch {
            // Silently fail — not critical
            NSLog("[DECK] Update check failed: \(error.localizedDescription)")
        }
    }

    /// The install command users should run
    static let installCommand = "curl -sL https://raw.githubusercontent.com/\(repo)/main/scripts/install.sh | bash"

    /// Download and install the update in the background, then prompt to relaunch
    func installUpdate() {
        guard updateAvailable else { return }
        isInstalling = true

        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", Self.installCommand]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    await MainActor.run {
                        self.updateAvailable = false
                        self.isInstalling = false
                        self.readyToRelaunch = true
                    }
                } else {
                    await MainActor.run { self.isInstalling = false }
                }
            } catch {
                await MainActor.run { self.isInstalling = false }
                NSLog("[DECK] Update install failed: \(error)")
            }
        }
    }

    /// Relaunch the app after update
    func relaunch() {
        let url = URL(fileURLWithPath: "/Applications/Deck.app")
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
}
