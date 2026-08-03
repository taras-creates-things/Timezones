import SwiftUI

struct PanelFooterView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack {
            Button {
                model.showSettings()
            } label: {
                footerIcon("gearshape")
            }
            .buttonStyle(PanelCircleButtonStyle())
            .help("Settings")
            .accessibilityLabel("Settings")

            Spacer()

            HStack(spacing: 6) {
                Button {
                    if reduceMotion {
                        model.resetToNow()
                    } else {
                        model.animateTimelineToNow()
                    }
                } label: {
                    footerIcon("scope")
                }
                .buttonStyle(PanelCircleButtonStyle())
                .help("Return to now")
                .accessibilityLabel("Return to now")

                Button {
                    model.showAddZone()
                } label: {
                    footerIcon("plus")
                }
                .buttonStyle(PanelCircleButtonStyle())
                .help("Add timezone")
                .accessibilityLabel("Add timezone")
            }
        }
        .padding(.horizontal, DesignTokens.horizontalPadding)
        .frame(height: DesignTokens.footerHeight)
    }

    private func footerIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .medium))
            .frame(width: 18, height: 18)
    }
}

private struct PanelCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .frame(
                width: DesignTokens.footerButtonSize,
                height: DesignTokens.footerButtonSize
            )
            .background(Color.clear)
            .overlay {
                Circle()
                    .stroke(
                        Color.primary.opacity(configuration.isPressed ? 0.34 : 0.20),
                        lineWidth: 1
                    )
            }
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
