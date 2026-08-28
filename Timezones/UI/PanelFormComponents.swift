import SwiftUI

struct PanelFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppTypography.secondary(size: 10, relativeTo: .caption2))
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)

            VStack(spacing: 0) {
                content
            }
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            }
        }
    }
}

struct PanelFormRow<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(AppTypography.primary(size: 14))
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 10)
    }
}

struct PanelFormDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 10)
    }
}
