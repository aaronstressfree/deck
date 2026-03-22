import SwiftUI
import WebKit

struct BrowserPaneView: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager
    @Binding var tabs: [BrowserTab]
    @Binding var activeTabId: UUID?
    @Binding var urlBarFocused: Bool

    @State private var urlInput: String = ""
    @State private var deviceFrame: DeviceFrame = .desktop
    @State private var webViewRef = WebViewRef()

    enum DeviceFrame: String, CaseIterable {
        case desktop = "Desktop"
        case tablet = "Tablet"
        case phone = "Phone"

        var width: CGFloat? {
            switch self {
            case .desktop: return nil
            case .tablet: return 768
            case .phone: return 375
            }
        }
        var icon: String {
            switch self {
            case .desktop: return "desktopcomputer"
            case .tablet: return "ipad"
            case .phone: return "iphone"
            }
        }
    }

    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == activeTabId })
    }

    var body: some View {
        VStack(spacing: 0) {
            browserTabBar
            urlBar
            browserContent
        }
        .background(theme.surfaces.primary.swiftUIColor)
        .overlay(
            // Inspect mode border indicator
            designMode.inspectMode
                ? RoundedRectangle(cornerRadius: 0).stroke(theme.accent.primary.swiftUIColor.opacity(0.4), lineWidth: 2)
                : nil
        )
        .onChange(of: urlBarFocused) { _, focused in
            if focused {
                // Show the live URL (from WKWebView, which may have been redirected) or the stored URL
                let liveURL = webViewRef.currentURL
                let storedURL = activeTab?.url
                let url = liveURL ?? storedURL
                urlInput = (url != nil && url != "about:blank") ? url! : ""
            }
        }
        // React to inspect mode changes from ANY source (Cmd+D, button, etc.)
        // Also wires live preview callbacks here — guaranteed to fire, unlike .onAppear
        .onChange(of: designMode.inspectMode) { _, isInspecting in
            // Wire callbacks every time (idempotent, closes .onAppear reliability gap)
            designMode.onLivePreview = { [weak webViewRef] property, value in
                webViewRef?.applyCSSChange(property: property, value: value)
            }
            designMode.onResetPreview = { [weak webViewRef] in
                webViewRef?.webView?.reload()
            }
            if isInspecting {
                webViewRef.enableInspectMode()
            } else {
                webViewRef.disableInspectMode()
            }
        }
        // Track selected element for live CSS preview
        .onChange(of: designMode.selectedElement?.selector) { _, selector in
            webViewRef.selectedSelector = selector
        }
        .onAppear {
            if tabs.isEmpty { addTab() }
        }
    }

    // MARK: - Browser content

    @ViewBuilder
    private var browserContent: some View {
        if let tab = activeTab, tab.url != "about:blank" {
            GeometryReader { geo in
                let contentWidth = deviceFrame.width ?? geo.size.width
                HStack {
                    Spacer(minLength: 0)
                    WebViewBridge(url: tab.url, ref: webViewRef, onElementSelected: { element in
                            designMode.selectElement(element)
                        })
                        .frame(width: min(contentWidth, geo.size.width))
                        .clipShape(RoundedRectangle(cornerRadius: deviceFrame == .desktop ? 0 : 12))
                        .overlay(
                            deviceFrame != .desktop
                                ? RoundedRectangle(cornerRadius: 12).stroke(theme.borders.primary.swiftUIColor, lineWidth: 2)
                                : nil
                        )
                        .padding(deviceFrame != .desktop ? 8 : 0)
                    Spacer(minLength: 0)
                }
                .background(deviceFrame != .desktop ? theme.surfaces.inset.swiftUIColor : Color.clear)
            }
        } else {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                VStack(spacing: 4) {
                    Text("Preview")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    Text("Enter a URL or start a dev server")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                }
                HStack(spacing: 16) {
                    shortcutHint("⌘L", "URL bar")
                    shortcutHint("⌘B", "Toggle")
                    shortcutHint("⌘R", "Reload")
                }
                .padding(.top, 4)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func shortcutHint(_ key: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.text.tertiary.swiftUIColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(theme.surfaces.hover.swiftUIColor))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
        }
    }

    // MARK: - Tab bar

    private var browserTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    let isActive = tab.id == activeTabId
                    HStack(spacing: 6) {
                        Text(tab.title)
                            .font(.system(size: 14))
                            .foregroundStyle(isActive ? theme.text.primary.swiftUIColor : theme.text.tertiary.swiftUIColor)
                            .lineLimit(1)
                            .frame(maxWidth: 160)
                        if tabs.count > 1 {
                            Button(action: { closeTab(tab.id) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isActive ? theme.surfaces.elevated.swiftUIColor : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { activeTabId = tab.id }
                }
                Button(action: addTab) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 34)
        .background(theme.surfaces.inset.swiftUIColor)
    }

    // MARK: - URL bar

    private var urlBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Navigation buttons
                HStack(spacing: 2) {
                    Button(action: { webViewRef.webView?.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    }
                    .buttonStyle(.plain)

                    Button(action: { webViewRef.webView?.goForward() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    }
                    .buttonStyle(.plain)

                    Button(action: { webViewRef.webView?.reload() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    }
                    .buttonStyle(.plain)
                }

                // URL input
                BrowserURLField(
                    text: $urlInput,
                    isFocused: $urlBarFocused,
                    textColor: theme.text.primary.nsColor,
                    placeholderColor: theme.text.quaternary.nsColor,
                    backgroundColor: theme.surfaces.inset.nsColor,
                    onSubmit: { navigateTo(urlInput) }
                )
                .frame(height: 28)

                // Right-side tools
                HStack(spacing: 2) {
                    // Inspect element
                    Button(action: { designMode.toggleInspect() }) {
                        Image(systemName: "cursorarrow.click.2")
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(designMode.inspectMode ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
                    }
                    .buttonStyle(.plain)
                    .help("Inspect element")

                    // Device frames
                    ForEach(DeviceFrame.allCases, id: \.rawValue) { frame in
                        Button(action: { deviceFrame = frame }) {
                            Image(systemName: frame.icon)
                                .font(.system(size: 14))
                                .frame(width: 28, height: 28)
                                .foregroundStyle(deviceFrame == frame ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
                        }
                        .buttonStyle(.plain)
                        .help(frame.rawValue)
                    }

                    // Open in system browser
                    Button(action: openExternal) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.surfaces.elevated.swiftUIColor)

        }
        .overlay(Rectangle().frame(height: 1).foregroundStyle(theme.borders.subtle.swiftUIColor), alignment: .bottom)
    }

    // MARK: - Actions

    private func navigateTo(_ url: String) {
        var s = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") && !s.hasPrefix("file://") {
            // Default to https for external sites, http for localhost
            if s.hasPrefix("localhost") || s.hasPrefix("127.0.0.1") || s.hasPrefix("0.0.0.0") {
                s = "http://" + s
            } else {
                s = "https://" + s
            }
        }
        if let index = tabs.firstIndex(where: { $0.id == activeTabId }) {
            tabs[index].url = s
            tabs[index].title = URL(string: s)?.host ?? s
        } else {
            let tab = BrowserTab(url: s)
            tabs.append(tab)
            activeTabId = tab.id
        }
        // Show the resolved URL in the URL bar
        urlInput = s
        urlBarFocused = false
    }

    private func addTab() {
        let tab = BrowserTab(url: "about:blank", title: "New Tab")
        tabs.append(tab)
        activeTabId = tab.id
        urlInput = ""
        urlBarFocused = true
    }

    private func closeTab(_ id: UUID) {
        tabs.removeAll(where: { $0.id == id })
        if activeTabId == id { activeTabId = tabs.last?.id }
    }

    private func openExternal() {
        guard let tab = activeTab, let url = URL(string: tab.url) else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - NSTextField-based URL bar (reliable keyboard focus)

struct BrowserURLField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let textColor: NSColor
    let placeholderColor: NSColor
    let backgroundColor: NSColor
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.delegate = context.coordinator
        tf.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        tf.textColor = textColor
        tf.backgroundColor = backgroundColor
        tf.isBordered = false
        tf.drawsBackground = true
        tf.placeholderString = "Search or enter URL"
        tf.placeholderAttributedString = NSAttributedString(
            string: "Search or enter URL",
            attributes: [.foregroundColor: placeholderColor, .font: NSFont.systemFont(ofSize: 14, weight: .regular)]
        )
        tf.focusRingType = .none
        tf.cell?.lineBreakMode = .byTruncatingTail

        // Rounded appearance
        tf.wantsLayer = true
        tf.layer?.cornerRadius = 6
        tf.layer?.masksToBounds = true

        context.coordinator.textField = tf
        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        if tf.stringValue != text { tf.stringValue = text }
        tf.textColor = textColor
        tf.backgroundColor = backgroundColor
        context.coordinator.parent = self

        if isFocused && tf.window?.firstResponder !== tf.currentEditor() {
            DispatchQueue.main.async {
                tf.window?.makeFirstResponder(tf)
                tf.selectText(nil)
            }
        }
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: BrowserURLField
        weak var textField: NSTextField?

        init(_ parent: BrowserURLField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

// MARK: - WebView with ref for back/forward/refresh + inspect

class WebViewRef {
    weak var webView: WKWebView?
    var inspectEnabled = false
    /// The CSS selector of the currently selected element (for live preview)
    var selectedSelector: String?
    /// Live page title from WKWebView KVO
    var currentTitle: String?
    /// Live loading state
    var isLoading: Bool = false
    /// Live URL from WKWebView KVO
    var currentURL: String?

    /// Apply a CSS property change live in the browser
    func applyCSSChange(property: String, value: String) {
        guard let wv = webView, let selector = selectedSelector else { return }
        // Escape for JS string
        let safeSelector = selector.replacingOccurrences(of: "'", with: "\\'")
        let safeProp = property.replacingOccurrences(of: "'", with: "\\'")
        let safeVal = value.replacingOccurrences(of: "'", with: "\\'")
        let js = """
        (function() {
            var el = document.querySelector('\(safeSelector)');
            if (!el && window.__deckSelectedEl) el = window.__deckSelectedEl;
            if (el) {
                el.style.setProperty('\(safeProp)', '\(safeVal)');
                console.log('[DECK] Applied', '\(safeProp)', '=', '\(safeVal)');
            }
        })();
        """
        wv.evaluateJavaScript(js)
    }

    func enableInspectMode() {
        inspectEnabled = true
        guard let wv = webView else {
            NSLog("[DECK-INSPECT] enableInspectMode: no webView")
            return
        }
        NSLog("[DECK-INSPECT] Injecting inspect JS")
        wv.evaluateJavaScript(WebViewRef.enableInspectJS) { _, error in
            if let error = error {
                NSLog("[DECK-INSPECT] JS inject error: \(error)")
            } else {
                NSLog("[DECK-INSPECT] JS injected OK")
            }
        }
    }

    func disableInspectMode() {
        inspectEnabled = false
        webView?.evaluateJavaScript(WebViewRef.disableInspectJS)
        NSLog("[DECK-INSPECT] Inspect mode disabled")
    }

    static let enableInspectJS = """
    (function() {
        // Remove old listeners if re-injecting
        if (window.__deckCleanup) window.__deckCleanup();

        window.__deckInspect = true;
        console.log('[DECK] Inspect mode enabled');

        // Overlay for hover highlight
        var overlay = document.getElementById('__deck_overlay');
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = '__deck_overlay';
            document.body.appendChild(overlay);
        }
        overlay.style.cssText = 'position:fixed;pointer-events:none;z-index:999999;border:2px solid #6366f1;background:rgba(99,102,241,0.08);transition:all 0.15s ease;display:none;border-radius:3px;';

        var selected = null;

        function getSelector(el) {
            if (el.id) return '#' + el.id;
            var parts = [];
            var cur = el;
            while (cur && cur !== document.body && cur !== document.documentElement) {
                var s = cur.tagName.toLowerCase();
                if (cur.className && typeof cur.className === 'string') {
                    var cls = cur.className.trim().split(/\\s+/).filter(function(c){ return c.length > 0; }).slice(0, 2).join('.');
                    if (cls) s += '.' + cls;
                }
                parts.unshift(s);
                cur = cur.parentElement;
                if (parts.length >= 3) break;
            }
            return parts.join(' > ');
        }

        function getStyles(el) {
            var cs = window.getComputedStyle(el);
            var result = {};
            var props = ['background-color','color','font-size','font-weight','line-height','letter-spacing',
                'text-align','padding-top','padding-right','padding-bottom','padding-left',
                'margin-top','margin-right','margin-bottom','margin-left',
                'border-top-width','border-radius','border-color','border-style',
                'width','height','display','flex-direction','justify-content','align-items',
                'gap','opacity','box-shadow'];
            for (var i = 0; i < props.length; i++) {
                result[props[i]] = cs.getPropertyValue(props[i]);
            }
            return result;
        }

        function onHover(e) {
            if (!window.__deckInspect) return;
            var t = e.target;
            if (t === overlay || t === document.body || t === document.documentElement) return;
            var rect = t.getBoundingClientRect();
            overlay.style.left = rect.left + 'px';
            overlay.style.top = rect.top + 'px';
            overlay.style.width = rect.width + 'px';
            overlay.style.height = rect.height + 'px';
            overlay.style.display = 'block';
        }

        function onClick(e) {
            if (!window.__deckInspect) return;
            e.preventDefault();
            e.stopPropagation();

            var el = e.target;
            if (el === overlay) return;

            // Remove old selection
            if (selected && selected.__deckOldOutline !== undefined) {
                selected.style.outline = selected.__deckOldOutline;
            }

            selected = el;
            window.__deckSelectedEl = el;
            el.__deckOldOutline = el.style.outline;
            el.style.outline = '2px solid #6366f1';

            // Hide hover overlay once selected
            overlay.style.display = 'none';

            var data = {
                selector: getSelector(el),
                tagName: el.tagName.toLowerCase(),
                className: (typeof el.className === 'string') ? el.className : '',
                styles: getStyles(el)
            };
            console.log('[DECK] Element selected:', data.selector);
            try {
                window.webkit.messageHandlers.deckInspect.postMessage(JSON.stringify(data));
            } catch(err) {
                console.error('[DECK] postMessage failed:', err);
            }
        }

        document.addEventListener('mousemove', onHover, true);
        document.addEventListener('click', onClick, true);

        // Store cleanup function for re-injection
        window.__deckCleanup = function() {
            document.removeEventListener('mousemove', onHover, true);
            document.removeEventListener('click', onClick, true);
            if (selected && selected.__deckOldOutline !== undefined) {
                selected.style.outline = selected.__deckOldOutline;
            }
            overlay.style.display = 'none';
        };
    })();
    """

    static let disableInspectJS = """
    (function() {
        window.__deckInspect = false;
        if (window.__deckCleanup) { window.__deckCleanup(); window.__deckCleanup = null; }
        var ov = document.getElementById('__deck_overlay');
        if (ov) ov.style.display = 'none';
        console.log('[DECK] Inspect mode disabled');
    })();
    """
}

struct WebViewBridge: NSViewRepresentable {
    let url: String
    let ref: WebViewRef
    var onElementSelected: ((SelectedElement) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onElementSelected: onElementSelected, ref: ref)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(context.coordinator, name: "deckInspect")

        // Modern Chrome user agent so sites render properly (Google, etc.)
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

        // Allow magnification (pinch to zoom)
        wv.allowsMagnification = true

        ref.webView = wv
        context.coordinator.observe(wv)
        if let u = URL(string: url) { wv.load(URLRequest(url: u)) }
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        ref.webView = wv
        context.coordinator.onElementSelected = onElementSelected

        // Only load if the URL actually changed (not just normalized differently).
        // WKWebView adds trailing slashes, follows redirects, etc. — compare hosts+paths loosely.
        if let newURL = URL(string: url) {
            let currentHost = wv.url?.host
            let newHost = newURL.host
            let currentPath = wv.url?.path
            let newPath = newURL.path

            // Load if: no page loaded yet, or the host/path genuinely changed
            let needsLoad = wv.url == nil
                || (currentHost != newHost)
                || (currentHost == newHost && currentPath != newPath && newPath != "/" && currentPath != "/")

            if needsLoad {
                wv.load(URLRequest(url: newURL))
            }
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var onElementSelected: ((SelectedElement) -> Void)?
        weak var ref: WebViewRef?
        private var titleObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?

        init(onElementSelected: ((SelectedElement) -> Void)?, ref: WebViewRef) {
            self.onElementSelected = onElementSelected
            self.ref = ref
        }

        /// Start observing WKWebView properties for title/loading/URL updates
        func observe(_ wv: WKWebView) {
            titleObservation = wv.observe(\.title) { [weak self] wv, _ in
                guard let title = wv.title, !title.isEmpty else { return }
                self?.ref?.currentTitle = title
            }
            loadingObservation = wv.observe(\.isLoading) { [weak self] wv, _ in
                self?.ref?.isLoading = wv.isLoading
            }
            urlObservation = wv.observe(\.url) { [weak self] wv, _ in
                self?.ref?.currentURL = wv.url?.absoluteString
            }
        }

        // Re-inject inspect JS after page finishes loading (if inspect mode is on)
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if ref?.inspectEnabled == true {
                ref?.enableInspectMode()
            }
        }

        // Handle HTTPS redirect failures gracefully
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            ref?.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            ref?.isLoading = false
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            NSLog("[DECK-INSPECT] Received message: \(message.name)")
            guard message.name == "deckInspect" else { return }

            // The message body could be a String (from JSON.stringify) or already a dict
            let json: [String: Any]?
            if let body = message.body as? String,
               let data = body.data(using: .utf8) {
                json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            } else if let body = message.body as? [String: Any] {
                json = body
            } else {
                NSLog("[DECK-INSPECT] Unexpected message body type: \(type(of: message.body))")
                return
            }

            guard let json = json else {
                NSLog("[DECK-INSPECT] Failed to parse JSON")
                return
            }

            let selector = json["selector"] as? String ?? ""
            let tagName = json["tagName"] as? String ?? ""
            let className = json["className"] as? String ?? ""
            let styles = json["styles"] as? [String: String] ?? [:]

            NSLog("[DECK-INSPECT] Selected: \(selector) (\(tagName)), \(styles.count) styles")

            let element = SelectedElement(
                selector: selector,
                tagName: tagName,
                className: className,
                computedStyles: styles
            )

            DispatchQueue.main.async {
                self.onElementSelected?(element)
            }
        }
    }
}
