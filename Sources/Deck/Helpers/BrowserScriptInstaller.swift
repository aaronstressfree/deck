import Foundation

/// Installs shell scripts that route URLs to Deck's browser pane.
/// Extracted from SessionManager for single-responsibility.
enum BrowserScriptInstaller {

    /// Install both the BROWSER env var handler and the `open` wrapper.
    static func install(urlQueuePath: String, browserScriptPath: String, deckBinDir: String) {
        installBrowserHandler(urlQueuePath: urlQueuePath, scriptPath: browserScriptPath)
        installOpenWrapper(urlQueuePath: urlQueuePath, binDir: deckBinDir)
    }

    private static func installBrowserHandler(urlQueuePath: String, scriptPath: String) {
        let script = """
        #!/bin/bash
        echo "$1" >> "\(urlQueuePath)"
        """
        do {
            try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
        } catch {
            NSLog("[DECK] Failed to install browser script: \(error)")
        }
    }

    private static func installOpenWrapper(urlQueuePath: String, binDir: String) {
        let script = """
        #!/bin/bash
        # Deck's open wrapper: routes http/https URLs to Deck's browser pane.
        # Non-URL arguments (files, apps, flags) pass through to /usr/bin/open.

        is_url=false
        url_arg=""

        for arg in "$@"; do
            case "$arg" in
                http://*|https://*)
                    is_url=true
                    url_arg="$arg"
                    ;;
            esac
        done

        if $is_url && [ -n "$url_arg" ]; then
            echo "$url_arg" >> "\(urlQueuePath)"
        else
            /usr/bin/open "$@"
        fi
        """
        let path = binDir + "/open"
        do {
            try script.write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
        } catch {
            NSLog("[DECK] Failed to install open wrapper script: \(error)")
        }
    }
}
