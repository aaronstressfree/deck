import SwiftUI

struct DesignChangesList: View {
    @Environment(\.deckTheme) private var theme
    @EnvironmentObject var designMode: DesignModeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Queued")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.text.tertiary.swiftUIColor)
                Spacer()
                Button("Clear") {
                    designMode.clearAll()
                }
                .font(.system(size: 11))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(designMode.instructionSet.changes) { change in
                        changeChip(change)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 6)
        }
        .frame(maxHeight: 80)
    }

    private func changeChip(_ change: DesignChange) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change.category.iconName)
                .font(.system(size: 8))
                .foregroundStyle(theme.accent.primary.swiftUIColor)
            Text("\(change.property): \(change.value)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.text.secondary.swiftUIColor)
                .lineLimit(1)
            Button(action: { designMode.removeChange(id: change.id) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(theme.surfaces.inset.swiftUIColor)
        .cornerRadius(4)
    }
}
