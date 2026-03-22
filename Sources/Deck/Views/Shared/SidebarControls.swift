import SwiftUI

/// A small icon button with hover state for sidebar use.
/// Uses the existing HoverButtonStyle for consistent hover feedback.
struct SidebarIconButton: View {
    let icon: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.text.quaternary.swiftUIColor)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
    }
}

/// A menu row with hover state for popover menus in the sidebar.
struct SidebarMenuRow: View {
    let icon: String
    let label: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.primary.swiftUIColor)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverButtonStyle(hoverColor: theme.surfaces.hover.swiftUIColor))
    }
}
