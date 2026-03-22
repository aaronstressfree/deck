import SwiftUI
import AppKit

/// A reusable color swatch: colored circle + label + hex value.
/// Click to open the native macOS color picker.
struct ColorSwatchView: View {
    let label: String
    @Binding var color: ThemeColor

    @State private var showingPicker = false

    var body: some View {
        HStack(spacing: 8) {
            // Color circle
            Circle()
                .fill(color.swiftUIColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture { showingPicker = true }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(color.hexString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ColorPickerSheet(label: label, color: $color)
        }
    }
}

struct ColorPickerSheet: View {
    let label: String
    @Binding var color: ThemeColor
    @Environment(\.dismiss) private var dismiss

    @State private var pickerColor: Color

    init(label: String, color: Binding<ThemeColor>) {
        self.label = label
        self._color = color
        self._pickerColor = State(initialValue: color.wrappedValue.swiftUIColor)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit \(label)")
                .font(.headline)

            ColorPicker("Color", selection: $pickerColor, supportsOpacity: true)
                .labelsHidden()

            // Hex input
            HStack {
                Text("Hex:")
                    .font(.system(size: 12))
                TextField("#000000", text: .constant(color.hexString))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(width: 100)
            }

            // Preview
            RoundedRectangle(cornerRadius: 8)
                .fill(pickerColor)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Apply") {
                    if let nsColor = NSColor(pickerColor).usingColorSpace(.sRGB) {
                        color = ThemeColor(
                            red: Double(nsColor.redComponent),
                            green: Double(nsColor.greenComponent),
                            blue: Double(nsColor.blueComponent),
                            opacity: Double(nsColor.alphaComponent)
                        )
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
