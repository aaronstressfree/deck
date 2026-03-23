import SwiftUI
import AppKit

/// An NSTextField for inline renaming that:
/// - Auto-focuses and selects all text on appear
/// - Commits on Enter or focus loss
/// - Cancels on Escape
struct RenameTextField: NSViewRepresentable {
    @Binding var text: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.delegate = context.coordinator
        tf.stringValue = text
        tf.font = .systemFont(ofSize: 14)
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.cell?.lineBreakMode = .byTruncatingTail

        // Auto-focus and select all
        DispatchQueue.main.async {
            tf.window?.makeFirstResponder(tf)
            tf.selectText(nil)
        }

        return tf
    }

    func updateNSView(_ tf: NSTextField, context: Context) {
        context.coordinator.parent = self
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: RenameTextField

        init(_ parent: RenameTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }

        // Commit on focus loss (clicking elsewhere)
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
    }
}
