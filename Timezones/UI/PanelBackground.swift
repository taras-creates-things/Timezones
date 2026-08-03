import SwiftUI

enum PanelSurfaceStyle {
    case header
    case content
}

struct PanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var style: PanelSurfaceStyle = .content

    var body: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)

            if colorScheme == .dark {
                darkSurface
            } else {
                lightSurface
            }
        }
    }

    @ViewBuilder
    private var darkSurface: some View {
        switch style {
        case .header:
            Color(red: 0.105, green: 0.115, blue: 0.128)
                .opacity(0.96)
        case .content:
            LinearGradient(
                colors: [
                    Color(red: 0.145, green: 0.157, blue: 0.173),
                    Color(red: 0.120, green: 0.132, blue: 0.147)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.96)
        }
    }

    @ViewBuilder
    private var lightSurface: some View {
        switch style {
        case .header:
            Color.white.opacity(0.82)
        case .content:
            LinearGradient(
                colors: [
                    Color(red: 0.955, green: 0.962, blue: 0.972),
                    Color(red: 0.925, green: 0.938, blue: 0.952)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.90)
        }
    }
}
