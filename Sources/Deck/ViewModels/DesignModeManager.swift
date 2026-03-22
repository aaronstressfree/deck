import SwiftUI
import AppKit

/// Data about a selected DOM element from the browser inspector.
struct SelectedElement {
    var selector: String       // CSS selector or description, e.g. "div.hero > h1"
    var tagName: String        // e.g. "h1", "div", "button"
    var className: String      // e.g. "hero-title primary"
    var computedStyles: [String: String]  // key CSS properties → current values
}

@MainActor
final class DesignModeManager: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var inspectMode: Bool = false   // true = clicks in browser select elements
    @Published var panelWidth: Double = 320
    @Published var instructionSet = DesignInstructionSet()
    @Published var showPreview: Bool = false
    @Published var copiedConfirmation: Bool = false
    @Published var selectedElement: SelectedElement?

    // Section collapsed state
    @Published var collapsedSections: Set<DesignCategory> = [.spacing, .layout, .sizing, .borders, .shadows, .effects]

    /// Closure to apply CSS changes live in the browser — set by BrowserPaneView
    var onLivePreview: ((_ property: String, _ value: String) -> Void)?
    /// Closure to reload the page (reset all live changes)
    var onResetPreview: (() -> Void)?

    var changeCount: Int { instructionSet.count }
    var hasChanges: Bool { !instructionSet.isEmpty }

    /// Toggle inspect mode — Cmd+D or clicking the inspect button
    func toggleInspect() {
        withAnimation(.easeOut(duration: 0.2)) {
            inspectMode.toggle()
            isVisible = inspectMode  // show panel when inspect mode is on
            if !inspectMode {
                selectedElement = nil
            }
        }
    }

    /// Called when an element is selected in the browser
    func selectElement(_ element: SelectedElement) {
        selectedElement = element
        instructionSet.target = element.selector
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = true
        }
    }

    /// Called when element is deselected
    func deselectElement() {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedElement = nil
            isVisible = false
            inspectMode = false
        }
    }

    /// Add or update a change. If a change with the same property and target
    /// already exists, update its value instead of creating a duplicate.
    func addChange(_ change: DesignChange) {
        var change = change
        if change.target.isEmpty {
            change.target = instructionSet.target
        }

        // Upsert: find existing change for same property + target
        if let idx = instructionSet.changes.firstIndex(where: {
            $0.property == change.property && $0.target == change.target
        }) {
            instructionSet.changes[idx].value = change.value
        } else {
            instructionSet.changes.append(change)
        }

        // Apply live in browser
        onLivePreview?(change.property, change.value)
    }

    /// Apply a CSS change in the browser without queuing it.
    /// Use for intermediate states (e.g. dragging a slider).
    func previewOnly(property: String, value: String) {
        onLivePreview?(property, value)
    }

    func removeChange(id: UUID) {
        instructionSet.changes.removeAll { $0.id == id }
    }

    func clearAll() {
        instructionSet.changes.removeAll()
    }

    /// Reset all live preview changes by reloading the browser page.
    func resetPreview() {
        clearAll()
        onResetPreview?()
    }

    func toggleSection(_ category: DesignCategory) {
        if collapsedSections.contains(category) {
            collapsedSections.remove(category)
        } else {
            collapsedSections.insert(category)
        }
    }

    func isSectionExpanded(_ category: DesignCategory) -> Bool {
        !collapsedSections.contains(category)
    }

    func syncWithBrowser(session: Session?) {
        guard let session = session else { return }
        if let activeTab = session.browserTabs.first(where: { $0.id == session.activeBrowserTabId }) {
            instructionSet.pageURL = activeTab.url
        } else if let firstTab = session.browserTabs.first {
            instructionSet.pageURL = firstTab.url
        }
    }

    func toMarkdown() -> String {
        instructionSet.toMarkdown()
    }

    func copyToClipboard() {
        let markdown = toMarkdown()
        guard !markdown.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        copiedConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.copiedConfirmation = false
        }
    }

    func sendToSession(controller: TerminalController) {
        let markdown = toMarkdown()
        guard !markdown.isEmpty else { return }
        controller.send(markdown)
        clearAll()
    }
}
