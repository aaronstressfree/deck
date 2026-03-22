#!/usr/bin/env swift

// Standalone test script for the Design Inspector data flow.
// Run: swift scripts/test-design-inspector.swift
// This tests the models and logic without importing the full app.

import Foundation

// ============================================================
// Replicate the minimal types needed for testing
// ============================================================

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
        if let url = pageURL, !url.isEmpty { lines.append("**Page:** \(url)") }
        if !target.isEmpty { lines.append("**Target:** \(target)") }
        if !globalNote.isEmpty { lines.append("**Note:** \(globalNote)") }
        if lines.count > 2 { lines.append("") }

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
                if let note = change.note, !note.isEmpty { line += " (\(note))" }
                lines.append(line)
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

struct SelectedElement {
    var selector: String
    var tagName: String
    var className: String
    var computedStyles: [String: String]
}

// ============================================================
// Test runner
// ============================================================

var passed = 0
var failed = 0

func test(_ name: String, _ block: () throws -> Void) {
    do {
        try block()
        passed += 1
        print("  ✅ \(name)")
    } catch {
        failed += 1
        print("  ❌ \(name): \(error)")
    }
}

struct TestFailure: Error {
    let message: String
}

func expect(_ condition: Bool, _ msg: String = "assertion failed") throws {
    if !condition {
        failed += 1
        throw TestFailure(message: msg)
    }
}

print("\n🧪 Design Inspector Tests\n")

// --- DesignChange ---

test("DesignChange creation") {
    let c = DesignChange(category: .color, property: "background-color", value: "#FF0000")
    try expect(c.category == .color, "category")
    try expect(c.property == "background-color", "property")
    try expect(c.value == "#FF0000", "value")
    try expect(c.target.isEmpty, "empty target")
}

test("DesignChange with target") {
    let c = DesignChange(category: .spacing, property: "padding", value: "16px", target: ".hero")
    try expect(c.target == ".hero", "target")
}

test("All 8 categories have icons") {
    try expect(DesignCategory.allCases.count == 8, "count")
    for cat in DesignCategory.allCases {
        try expect(!cat.iconName.isEmpty, "\(cat.rawValue) icon")
    }
}

// --- DesignInstructionSet ---

test("Empty instruction set") {
    let s = DesignInstructionSet()
    try expect(s.isEmpty, "isEmpty")
    try expect(s.count == 0, "count")
    try expect(s.toMarkdown() == "", "empty markdown")
}

test("Markdown generation") {
    var s = DesignInstructionSet()
    s.target = ".hero"
    s.pageURL = "http://localhost:3000"
    s.changes.append(DesignChange(category: .color, property: "background-color", value: "#1E293B"))
    s.changes.append(DesignChange(category: .spacing, property: "padding", value: "24px"))
    let md = s.toMarkdown()
    try expect(md.contains("## Design Changes"), "header")
    try expect(md.contains("**Page:** http://localhost:3000"), "page URL")
    try expect(md.contains("**Target:** .hero"), "target")
    try expect(md.contains("### Color"), "color section")
    try expect(md.contains("`background-color`"), "bg property")
    try expect(md.contains("`#1E293B`"), "bg value")
    try expect(md.contains("### Spacing"), "spacing section")
    try expect(md.contains("`padding`"), "padding property")
}

test("Markdown groups by category order (color before typography)") {
    var s = DesignInstructionSet()
    s.changes.append(DesignChange(category: .typography, property: "font-size", value: "18px"))
    s.changes.append(DesignChange(category: .color, property: "color", value: "red"))
    let md = s.toMarkdown()
    let ci = md.range(of: "### Color")!.lowerBound
    let ti = md.range(of: "### Typography")!.lowerBound
    try expect(ci < ti, "color before typography")
}

test("Markdown shows per-element target when different from global") {
    var s = DesignInstructionSet()
    s.target = ".container"
    s.changes.append(DesignChange(category: .color, property: "color", value: "red", target: ".title"))
    let md = s.toMarkdown()
    try expect(md.contains("On `.title`"), "per-element target")
}

test("Markdown hides per-element target when same as global") {
    var s = DesignInstructionSet()
    s.target = ".hero"
    s.changes.append(DesignChange(category: .color, property: "color", value: "red", target: ".hero"))
    let md = s.toMarkdown()
    try expect(!md.contains("On `.hero`"), "no redundant target")
}

// --- SelectedElement ---

test("SelectedElement stores computed styles") {
    let el = SelectedElement(
        selector: "div.card > h2",
        tagName: "h2",
        className: "card-title bold",
        computedStyles: ["font-size": "20px", "color": "rgb(26,26,26)", "padding": "0px"]
    )
    try expect(el.selector == "div.card > h2", "selector")
    try expect(el.tagName == "h2", "tag")
    try expect(el.className == "card-title bold", "classes")
    try expect(el.computedStyles.count == 3, "3 styles")
    try expect(el.computedStyles["font-size"] == "20px", "font-size value")
}

// --- Upsert behavior ---

test("Upsert: repeated changes to same property update instead of duplicating") {
    var set = DesignInstructionSet()
    set.target = ".btn"

    // Simulate clicking font-size stepper 3 times: 16→17→18
    func upsert(_ change: DesignChange) {
        var c = change
        if c.target.isEmpty { c.target = set.target }
        if let idx = set.changes.firstIndex(where: { $0.property == c.property && $0.target == c.target }) {
            set.changes[idx].value = c.value
        } else {
            set.changes.append(c)
        }
    }

    upsert(DesignChange(category: .typography, property: "font-size", value: "16px"))
    try expect(set.count == 1, "first click: 1 change")

    upsert(DesignChange(category: .typography, property: "font-size", value: "17px"))
    try expect(set.count == 1, "second click: still 1 change")

    upsert(DesignChange(category: .typography, property: "font-size", value: "18px"))
    try expect(set.count == 1, "third click: still 1 change")
    try expect(set.changes.first?.value == "18px", "value is latest (18px)")
}

test("Upsert: different properties create separate changes") {
    var set = DesignInstructionSet()
    set.target = ".btn"

    func upsert(_ change: DesignChange) {
        var c = change
        if c.target.isEmpty { c.target = set.target }
        if let idx = set.changes.firstIndex(where: { $0.property == c.property && $0.target == c.target }) {
            set.changes[idx].value = c.value
        } else {
            set.changes.append(c)
        }
    }

    upsert(DesignChange(category: .typography, property: "font-size", value: "16px"))
    upsert(DesignChange(category: .color, property: "color", value: "red"))
    try expect(set.count == 2, "two different properties = 2 changes")
}

test("Live preview callback fires on every change") {
    var calls: [(String, String)] = []
    let callback: (String, String) -> Void = { p, v in calls.append((p, v)) }

    var set = DesignInstructionSet()
    set.target = ".btn"

    func addWithPreview(_ change: DesignChange) {
        var c = change
        if c.target.isEmpty { c.target = set.target }
        if let idx = set.changes.firstIndex(where: { $0.property == c.property && $0.target == c.target }) {
            set.changes[idx].value = c.value
        } else {
            set.changes.append(c)
        }
        callback(c.property, c.value)
    }

    addWithPreview(DesignChange(category: .typography, property: "font-size", value: "16px"))
    addWithPreview(DesignChange(category: .typography, property: "font-size", value: "17px"))
    addWithPreview(DesignChange(category: .typography, property: "font-size", value: "18px"))

    try expect(calls.count == 3, "preview called 3 times (once per click)")
    try expect(set.count == 1, "but only 1 change queued")
    try expect(calls.last?.1 == "18px", "last preview was 18px")
}

// --- Simulated DesignModeManager flow ---

test("Manager: add change auto-fills target") {
    var set = DesignInstructionSet()
    set.target = ".hero"
    var change = DesignChange(category: .color, property: "color", value: "red")
    if change.target.isEmpty { change.target = set.target }
    set.changes.append(change)
    try expect(set.changes.first?.target == ".hero", "target auto-filled")
}

test("Manager: add change keeps explicit target") {
    var set = DesignInstructionSet()
    set.target = ".hero"
    var change = DesignChange(category: .color, property: "color", value: "red", target: ".custom")
    if change.target.isEmpty { change.target = set.target }
    set.changes.append(change)
    try expect(set.changes.first?.target == ".custom", "explicit target kept")
}

test("Manager: clear all") {
    var set = DesignInstructionSet()
    set.changes.append(DesignChange(category: .color, property: "color", value: "red"))
    set.changes.append(DesignChange(category: .spacing, property: "padding", value: "8px"))
    set.changes.removeAll()
    try expect(set.count == 0, "cleared")
    try expect(set.isEmpty, "empty")
}

test("Manager: remove specific change") {
    var set = DesignInstructionSet()
    let c = DesignChange(category: .color, property: "color", value: "red")
    set.changes.append(c)
    set.changes.append(DesignChange(category: .spacing, property: "padding", value: "8px"))
    set.changes.removeAll { $0.id == c.id }
    try expect(set.count == 1, "one remaining")
    try expect(set.changes.first?.category == .spacing, "spacing remains")
}

test("Full round trip: select → add changes → generate markdown") {
    let el = SelectedElement(selector: "button.primary", tagName: "button", className: "primary cta", computedStyles: [:])
    var set = DesignInstructionSet()
    set.target = el.selector
    set.pageURL = "http://localhost:5200/checkout"

    var c1 = DesignChange(category: .color, property: "background-color", value: "#6366f1")
    if c1.target.isEmpty { c1.target = set.target }
    set.changes.append(c1)

    var c2 = DesignChange(category: .typography, property: "font-size", value: "16px")
    if c2.target.isEmpty { c2.target = set.target }
    set.changes.append(c2)

    var c3 = DesignChange(category: .borders, property: "border-radius", value: "8px")
    if c3.target.isEmpty { c3.target = set.target }
    set.changes.append(c3)

    let md = set.toMarkdown()
    try expect(md.contains("## Design Changes"), "header")
    try expect(md.contains("**Page:** http://localhost:5200/checkout"), "page")
    try expect(md.contains("**Target:** button.primary"), "target")
    try expect(md.contains("### Color"), "color section")
    try expect(md.contains("`background-color`"), "bg prop")
    try expect(md.contains("`#6366f1`"), "bg value")
    try expect(md.contains("### Typography"), "typo section")
    try expect(md.contains("`font-size`"), "font prop")
    try expect(md.contains("### Borders"), "border section")
    try expect(md.contains("`border-radius`"), "radius prop")
    try expect(set.count == 3, "3 changes total")

    // Verify no per-element targets shown (all match global)
    try expect(!md.contains("On `button.primary`"), "no redundant per-element target")
}

print("\n📊 Results: \(passed) passed, \(failed) failed\n")
if failed > 0 { exit(1) }
