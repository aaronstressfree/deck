import SwiftUI

/// Wraps content in a device-shaped bezel for preview purposes.
struct DeviceFrameView<Content: View>: View {
    @Environment(\.deckTheme) private var theme
    let device: DeviceType
    let content: Content

    enum DeviceType {
        case phone
        case tablet

        var bezelRadius: CGFloat {
            switch self {
            case .phone: return 24
            case .tablet: return 16
            }
        }

        var bezelWidth: CGFloat {
            switch self {
            case .phone: return 8
            case .tablet: return 6
            }
        }
    }

    init(device: DeviceType, @ViewBuilder content: () -> Content) {
        self.device = device
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: device.bezelRadius - device.bezelWidth))
            .padding(device.bezelWidth)
            .background(
                RoundedRectangle(cornerRadius: device.bezelRadius)
                    .fill(theme.borders.primary.swiftUIColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: device.bezelRadius)
                    .stroke(theme.borders.hover.swiftUIColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
