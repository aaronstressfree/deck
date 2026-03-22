import SwiftUI

/// Searchable palette of Market React components.
struct MarketPaletteView: View {
    @Environment(\.deckTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    let onPaste: (String) -> Void

    struct MarketComponent: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let importPath: String
        let usage: String
        let category: String
    }

    let components: [MarketComponent] = [
        MarketComponent(name: "MarketButton", description: "Primary action button", importPath: "@squareup/market-react", usage: "<MarketButton rank=\"primary\">Label</MarketButton>", category: "Buttons"),
        MarketComponent(name: "MarketInput", description: "Text input field", importPath: "@squareup/market-react", usage: "<MarketInput><label slot=\"label\">Label</label></MarketInput>", category: "Inputs"),
        MarketComponent(name: "MarketSelect", description: "Dropdown select", importPath: "@squareup/market-react", usage: "<MarketSelect><label slot=\"label\">Label</label></MarketSelect>", category: "Inputs"),
        MarketComponent(name: "MarketRow", description: "List row item", importPath: "@squareup/market-react", usage: "<MarketRow><label slot=\"label\">Label</label></MarketRow>", category: "Layout"),
        MarketComponent(name: "MarketModal", description: "Modal dialog", importPath: "@squareup/market-react", usage: "<MarketModal>Content</MarketModal>", category: "Feedback"),
        MarketComponent(name: "MarketTable", description: "Data table", importPath: "@squareup/market-react", usage: "<MarketTable>...</MarketTable>", category: "Data Display"),
        MarketComponent(name: "MarketToggle", description: "Toggle switch", importPath: "@squareup/market-react", usage: "<MarketToggle><label slot=\"label\">Label</label></MarketToggle>", category: "Inputs"),
        MarketComponent(name: "MarketBanner", description: "Notification banner", importPath: "@squareup/market-react", usage: "<MarketBanner variant=\"info\">Message</MarketBanner>", category: "Feedback"),
    ]

    var filteredComponents: [MarketComponent] {
        if searchText.isEmpty { return components }
        return components.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Market Components")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search components...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Component list
            List(filteredComponents) { component in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(component.name)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        Spacer()
                        Text(component.category)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.gray.opacity(0.15))
                            )
                    }
                    Text(component.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("Copy Import + Usage") {
                            let text = "import { \(component.name) } from '\(component.importPath)';\n\(component.usage)"
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }
                        .font(.system(size: 11))

                        Button("Paste to Session") {
                            let text = "import { \(component.name) } from '\(component.importPath)';\n\(component.usage)"
                            onPaste(text)
                            dismiss()
                        }
                        .font(.system(size: 11))
                    }
                    .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 500, height: 500)
    }
}
