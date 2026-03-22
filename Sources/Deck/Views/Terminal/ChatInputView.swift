import SwiftUI
import AppKit
import SwiftTerm

/// Represents an attached file (pasted image or picked file)
struct AttachedFile: Identifiable {
    let id = UUID()
    let path: String
    let fileName: String
    let thumbnail: NSImage
    let isImage: Bool
}

/// Chat input bar. Enter sends. Shift+Enter for newlines. Supports image paste & file attach.
/// Workspace toggles live in a utility bar above (in TerminalContainerView).
struct ChatInputView: View {
    @Environment(\.deckTheme) private var theme
    @ObservedObject var sessionManager: SessionManager

    let sessionId: UUID
    let agentType: AgentType
    let onSend: (String) -> Void

    @State private var inputText: String = ""
    @State private var inputHeight: CGFloat = 28
    @State private var attachedFiles: [AttachedFile] = []
    @State private var focusTrigger = UUID()
    @State private var isDropTargeted = false

    private var isChatMode: Bool {
        sessionManager.isChatMode(for: sessionId)
    }

    private var canSend: Bool {
        !inputText.isEmpty || !attachedFiles.isEmpty
    }

    var body: some View {
        if isChatMode {
            chatBar
        } else {
            rawBar
        }
    }

    // MARK: - Raw mode bar

    private var rawBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 14))
                .foregroundStyle(theme.status.warning.primary.swiftUIColor)
            Text("Raw mode — keystrokes go to terminal")
                .font(.system(size: 14))
                .foregroundStyle(theme.text.secondary.swiftUIColor)
            Spacer()
            Button("Switch to Chat") {
                sessionManager.toggleChatMode(for: sessionId)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(theme.accent.primary.swiftUIColor)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(theme.accent.subtle.swiftUIColor))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.surfaces.elevated.swiftUIColor)
    }

    // MARK: - Chat input bar

    private var chatBar: some View {
        VStack(spacing: 0) {
            // Attachment preview strip
            if !attachedFiles.isEmpty {
                attachmentStrip
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Attach file
                Button(action: openFilePicker) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }
                .buttonStyle(.plain)
                .help("Attach file")
                .accessibilityIdentifier(AccessibilityID.toolsAttachFile)
                .padding(.bottom, 4)

                ChatTextField(
                    text: $inputText,
                    placeholder: attachedFiles.isEmpty ? agentType.inputPlaceholder : "Add a message...",
                    textColor: theme.text.primary.nsColor,
                    placeholderColor: theme.text.quaternary.nsColor,
                    cursorColor: theme.accent.primary.nsColor,
                    onSubmit: sendMessage,
                    onHeightChange: { inputHeight = $0 },
                    onImagePaste: handleImagePaste,
                    focusTrigger: focusTrigger
                )
                .frame(height: max(28, min(inputHeight, 100)))

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(canSend ? theme.accent.primary.swiftUIColor : theme.text.quaternary.swiftUIColor)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityIdentifier(AccessibilityID.sendButton)
                .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.surfaces.elevated.swiftUIColor)
        .contentShape(Rectangle())
        .onTapGesture { focusTrigger = UUID() }
        .dropDestination(for: URL.self) { urls, _ in
            handleDroppedURLs(urls)
            return !urls.isEmpty
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isDropTargeted ? theme.accent.primary.swiftUIColor : theme.borders.primary.swiftUIColor,
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Attachment preview strip

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachedFiles) { file in
                    attachmentChip(file)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    private func attachmentChip(_ file: AttachedFile) -> some View {
        ZStack(alignment: .topTrailing) {
            if file.isImage {
                // Image thumbnail
                Image(nsImage: file.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(theme.borders.subtle.swiftUIColor, lineWidth: 1)
                    )
            } else {
                // File icon + name
                VStack(spacing: 4) {
                    Image(nsImage: file.thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                    Text(file.fileName)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.text.secondary.swiftUIColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(width: 72, height: 60)
                .background(RoundedRectangle(cornerRadius: 6).fill(theme.surfaces.primary.swiftUIColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.borders.subtle.swiftUIColor, lineWidth: 1)
                )
            }

            Button(action: { removeFile(file.id) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                    .background(Circle().fill(theme.surfaces.elevated.swiftUIColor).frame(width: 12, height: 12))
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard canSend else { return }

        var message = inputText

        // Append file paths for the agent to read
        for file in attachedFiles {
            if !message.isEmpty { message += "\n" }
            message += file.path
        }

        // Send text followed by carriage return (\r) — this is what pressing Enter
        // in a terminal actually sends. \n doesn't trigger command submission in
        // most terminal applications (Claude Code, Amp, zsh, bash).
        onSend(message + "\r")
        inputText = ""
        attachedFiles = []
        inputHeight = 28
    }

    private func handleImagePaste(_ image: NSImage, _ path: String) {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        attachedFiles.append(AttachedFile(path: path, fileName: fileName, thumbnail: image, isImage: true))
    }

    private func removeFile(_ id: UUID) {
        attachedFiles.removeAll { $0.id == id }
    }

    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif", "heic"
    ]

    private func attachFileURLs(_ urls: [URL]) {
        for url in urls {
            guard url.isFileURL else { continue }
            let path = url.path
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            if Self.imageExtensions.contains(ext), let image = NSImage(contentsOf: url) {
                attachedFiles.append(AttachedFile(path: path, fileName: fileName, thumbnail: image, isImage: true))
            } else {
                let icon = NSWorkspace.shared.icon(forFile: path)
                attachedFiles.append(AttachedFile(path: path, fileName: fileName, thumbnail: icon, isImage: false))
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false

        guard panel.runModal() == .OK else { return }
        attachFileURLs(panel.urls)

        // Refocus chat input after panel closes
        focusTrigger = UUID()
    }

    private func handleDroppedURLs(_ urls: [URL]) {
        attachFileURLs(urls)
        focusTrigger = UUID()
    }
}

// MARK: - NSTextView-based input (Enter sends, Shift+Enter newlines, image paste)

struct ChatTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let textColor: NSColor
    let placeholderColor: NSColor
    let cursorColor: NSColor
    let onSubmit: () -> Void
    let onHeightChange: (CGFloat) -> Void
    var onImagePaste: ((NSImage, String) -> Void)? = nil
    var focusTrigger: UUID = UUID()

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> DeckChatTextView {
        let tv = DeckChatTextView()
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.textColor = textColor
        tv.backgroundColor = .clear
        tv.insertionPointColor = cursorColor
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.textContainerInset = NSSize(width: 0, height: 6)
        tv.textContainer?.widthTracksTextView = true
        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable = true
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: 100)
        tv.onImagePaste = context.coordinator.handleImagePaste

        context.coordinator.textView = tv
        context.coordinator.lastFocusTrigger = focusTrigger

        // Auto-focus after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tv.window?.makeFirstResponder(tv)
        }

        return tv
    }

    func updateNSView(_ tv: DeckChatTextView, context: Context) {
        // Only sync text if it changed externally (e.g. clear after send)
        if tv.string != text {
            tv.string = text
        }

        // Only update colors if they actually changed — avoid work during typing
        if tv.textColor != textColor { tv.textColor = textColor }
        if tv.insertionPointColor != cursorColor { tv.insertionPointColor = cursorColor }

        context.coordinator.parent = self

        // Focus when trigger changes (e.g. user tapped the chat bar or file picker closed)
        if context.coordinator.lastFocusTrigger != focusTrigger {
            context.coordinator.lastFocusTrigger = focusTrigger
            DispatchQueue.main.async {
                tv.window?.makeFirstResponder(tv)
            }
        }

        // Auto-grab focus in chat mode — but only if we don't already have it.
        // This prevents unnecessary makeFirstResponder calls on every render.
        if let window = tv.window {
            let fr = window.firstResponder
            // For NSTextView, it IS the first responder directly (no field editor indirection)
            let alreadyFocused = fr === tv
            if !alreadyFocused {
                let shouldGrabFocus = fr == nil || fr === window || fr is TerminalView
                if shouldGrabFocus {
                    DispatchQueue.main.async {
                        window.makeFirstResponder(tv)
                    }
                }
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatTextField
        weak var textView: NSTextView?
        var lastFocusTrigger: UUID = UUID()
        private var heightDebounce: DispatchWorkItem?

        init(_ parent: ChatTextField) { self.parent = parent }

        func handleImagePaste(_ image: NSImage, _ path: String) {
            parent.onImagePaste?(image, path)
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string

            // Debounce height recalculation — ensureLayout is expensive,
            // no need to run it on every keystroke
            heightDebounce?.cancel()
            let work = DispatchWorkItem { [weak self, weak tv] in
                guard let tv, let self else { return }
                guard let layoutManager = tv.layoutManager,
                      let textContainer = tv.textContainer else { return }
                layoutManager.ensureLayout(for: textContainer)
                let height = layoutManager.usedRect(for: textContainer).height
                self.parent.onHeightChange(height + 12)
            }
            heightDebounce = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }

        // Enter → send, Shift+Enter → newline
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let flags = NSApp.currentEvent?.modifierFlags ?? []
                if flags.contains(.shift) {
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    parent.onSubmit()
                    return true
                }
            }
            return false
        }
    }
}

// MARK: - NSTextView subclass with image paste support

class DeckChatTextView: NSTextView {
    var onImagePaste: ((NSImage, String) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func paste(_ sender: Any?) {
        let pb = NSPasteboard.general
        let imageTypes: Set<NSPasteboard.PasteboardType> = [.tiff, .png]
        let hasImage = pb.types?.contains(where: { imageTypes.contains($0) }) ?? false

        if hasImage, let image = NSImage(pasteboard: pb) {
            // Convert to PNG and save to temp file
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                super.paste(sender)
                return
            }

            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("deck-images")
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                let filePath = tempDir.appendingPathComponent("\(UUID().uuidString).png")
                try pngData.write(to: filePath)
                onImagePaste?(image, filePath.path)
            } catch {
                NSLog("[DECK] Failed to save pasted image: \(error)")
                super.paste(sender)
            }
            return
        }

        // Normal text paste
        super.paste(sender)
    }
}
