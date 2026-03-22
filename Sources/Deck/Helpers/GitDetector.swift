import Foundation

/// Detects git information for a given directory.
enum GitDetector {
    /// Get the current git branch for a directory.
    static func currentBranch(in directory: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["-C", directory, "rev-parse", "--abbrev-ref", "HEAD"]
        task.standardError = FileHandle.nullDevice

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            guard task.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Cache for git root lookups — avoids spawning a subprocess for the same directory
    private static var rootCache: [String: String?] = [:]

    /// Get the root directory of the git repository containing the given directory.
    /// Returns nil if the directory is not inside a git repo. Results are cached.
    static func rootDirectory(for directory: String) -> String? {
        if let cached = rootCache[directory] { return cached }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["-C", directory, "rev-parse", "--show-toplevel"]
        task.standardError = FileHandle.nullDevice

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else {
                rootCache[directory] = nil
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            rootCache[directory] = result
            return result
        } catch {
            rootCache[directory] = nil
            return nil
        }
    }

    /// Check if a directory is a git repository.
    static func isGitRepo(directory: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["-C", directory, "rev-parse", "--is-inside-work-tree"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Check if there are uncommitted changes.
    static func isDirty(directory: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = ["-C", directory, "status", "--porcelain"]
        task.standardError = FileHandle.nullDevice

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Async wrappers (run git on a background thread)

    /// Async version — runs git on a background thread
    static func currentBranchAsync(in directory: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: currentBranch(in: directory))
            }
        }
    }

    /// Async version — runs git on a background thread
    static func rootDirectoryAsync(for directory: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: rootDirectory(for: directory))
            }
        }
    }

    /// Async version — runs git on a background thread
    static func isGitRepoAsync(directory: String) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: isGitRepo(directory: directory))
            }
        }
    }

    /// Async version — runs git on a background thread
    static func isDirtyAsync(directory: String) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: isDirty(directory: directory))
            }
        }
    }
}
