import Foundation

enum DesignCategory: String, CaseIterable, Codable, Identifiable {
    case color = "Color"
    case spacing = "Spacing"
    case typography = "Typography"
    case layout = "Layout"
    case sizing = "Sizing"
    case borders = "Borders"
    case shadows = "Shadows"
    case effects = "Effects"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .color: "paintpalette"
        case .spacing: "square.dashed"
        case .typography: "textformat.size"
        case .layout: "rectangle.3.group"
        case .sizing: "arrow.up.left.and.arrow.down.right"
        case .borders: "square"
        case .shadows: "shadow"
        case .effects: "wand.and.stars"
        }
    }
}

struct DesignChange: Identifiable, Hashable {
    let id: UUID
    var category: DesignCategory
    var property: String
    var value: String
    var target: String
    var note: String?

    init(category: DesignCategory, property: String, value: String, target: String = "", note: String? = nil) {
        self.id = UUID()
        self.category = category
        self.property = property
        self.value = value
        self.target = target
        self.note = note
    }
}

struct DesignInstructionSet {
    var changes: [DesignChange] = []
    var globalNote: String = ""
    var pageURL: String?
    var target: String = ""

    var isEmpty: Bool { changes.isEmpty }
    var count: Int { changes.count }

    func toMarkdown() -> String {
        guard !changes.isEmpty else { return "" }

        var lines: [String] = ["## Design Changes", ""]

        if let url = pageURL, !url.isEmpty {
            lines.append("**Page:** \(url)")
        }
        if !target.isEmpty {
            lines.append("**Target:** \(target)")
        }
        if !globalNote.isEmpty {
            lines.append("**Note:** \(globalNote)")
        }
        if lines.count > 2 {
            lines.append("")
        }

        let grouped = Dictionary(grouping: changes) { $0.category }
        for category in DesignCategory.allCases {
            guard let items = grouped[category] else { continue }
            lines.append("### \(category.rawValue)")
            for change in items {
                var line = "- "
                if !change.target.isEmpty && change.target != target {
                    line += "On `\(change.target)`: "
                }
                line += "Change `\(change.property)` to `\(change.value)`"
                if let note = change.note, !note.isEmpty {
                    line += " (\(note))"
                }
                lines.append(line)
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
