import SwiftUI

struct DesignLayoutSection: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    @State private var display: String = "flex"
    @State private var flexDirection: String = "row"
    @State private var justifyContent: String = "start"
    @State private var alignItems: String = "stretch"

    var body: some View {
        inspectorSection(
            category: .layout,
            theme: theme,
            designMode: designMode
        ) {
            // Display
            HStack(spacing: 0) {
                Text("Display")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $display) {
                    Text("block").tag("block")
                    Text("flex").tag("flex")
                    Text("grid").tag("grid")
                    Text("none").tag("none")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: display) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .layout,
                    property: "display",
                    value: newValue
                ))
            }

            // Direction
            HStack(spacing: 0) {
                Text("Direction")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $flexDirection) {
                    Text("row").tag("row")
                    Text("col").tag("column")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: flexDirection) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .layout,
                    property: "flex-direction",
                    value: newValue
                ))
            }

            // Justify
            HStack(spacing: 0) {
                Text("Justify")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $justifyContent) {
                    Image(systemName: "align.horizontal.left").tag("start")
                    Image(systemName: "align.horizontal.center").tag("center")
                    Image(systemName: "align.horizontal.right").tag("end")
                    Image(systemName: "distribute.horizontal.center").tag("space-between")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: justifyContent) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .layout,
                    property: "justify-content",
                    value: newValue
                ))
            }

            // Align
            HStack(spacing: 0) {
                Text("Align")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                    .frame(width: 54, alignment: .leading)
                Picker("", selection: $alignItems) {
                    Text("start").tag("start")
                    Text("center").tag("center")
                    Text("end").tag("end")
                    Text("stretch").tag("stretch")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .onChange(of: alignItems) { _, newValue in
                designMode.addChange(DesignChange(
                    category: .layout,
                    property: "align-items",
                    value: newValue
                ))
            }
        }
    }
}
