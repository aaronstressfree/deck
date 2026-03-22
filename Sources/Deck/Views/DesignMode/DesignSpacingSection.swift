import SwiftUI

struct DesignSpacingSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var paddingTop: String = ""
    @State private var paddingRight: String = ""
    @State private var paddingBottom: String = ""
    @State private var paddingLeft: String = ""

    @State private var marginTop: String = ""
    @State private var marginRight: String = ""
    @State private var marginBottom: String = ""
    @State private var marginLeft: String = ""

    @State private var gap: String = ""

    var body: some View {
        inspectorSection(
            category: .spacing,
            theme: theme,
            designMode: designMode
        ) {
            // Padding sub-group
            Text("Padding")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                compactField("T", value: $paddingTop) { commitSpacing("padding-top", paddingTop) }
                compactField("R", value: $paddingRight) { commitSpacing("padding-right", paddingRight) }
            }
            HStack(spacing: 6) {
                compactField("B", value: $paddingBottom) { commitSpacing("padding-bottom", paddingBottom) }
                compactField("L", value: $paddingLeft) { commitSpacing("padding-left", paddingLeft) }
            }

            // Margin sub-group
            Text("Margin")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            HStack(spacing: 6) {
                compactField("T", value: $marginTop) { commitSpacing("margin-top", marginTop) }
                compactField("R", value: $marginRight) { commitSpacing("margin-right", marginRight) }
            }
            HStack(spacing: 6) {
                compactField("B", value: $marginBottom) { commitSpacing("margin-bottom", marginBottom) }
                compactField("L", value: $marginLeft) { commitSpacing("margin-left", marginLeft) }
            }

            // Gap
            InspectorField(label: "Gap", value: $gap, placeholder: "0") {
                commitSpacing("gap", gap)
            }
            .padding(.top, 4)
        }
    }

    private func compactField(_ label: String, value: Binding<String>, onCommit: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .frame(width: 14, alignment: .leading)
            TextField("0", text: value)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(theme.surfaces.inset.swiftUIColor)
                .cornerRadius(4)
                .onSubmit { onCommit() }
        }
    }

    private func commitSpacing(_ property: String, _ value: String) {
        guard !value.isEmpty else { return }
        let formatted = value.hasSuffix("px") || value.hasSuffix("rem") || value.hasSuffix("%") ? value : "\(value)px"
        designMode.addChange(DesignChange(
            category: .spacing,
            property: property,
            value: formatted
        ))
    }
}
