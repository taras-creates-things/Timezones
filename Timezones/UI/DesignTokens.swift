import AppKit
import SwiftUI

enum DesignTokens {
    static let panelWidth: CGFloat = 360
    static let rulerHeight: CGFloat = 86
    static let rowHeight: CGFloat = 64
    static let footerHeight: CGFloat = 60
    static let footerButtonSize: CGFloat = 36
    static let maximumVisibleRows = 5
    static let horizontalPadding: CGFloat = 12
    static let cellInset: CGFloat = 12
    static let cornerRadius: CGFloat = 13
}

struct PanelSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var appKitAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

extension WorkStatus {
    var color: Color {
        switch self {
        case .working: .green
        case .wrappingUp: Color("AccentColor")
        case .beforeWork: .yellow
        case .night: .secondary
        case .weekend: .secondary
        }
    }
}
