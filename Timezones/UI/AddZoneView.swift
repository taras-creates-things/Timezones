import SwiftUI

struct AddZoneView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private var results: [TimeZoneOption] {
        TimeZoneSearchIndex.search(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    model.showMainPanel()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .help("Back")

                Text("Add timezone")
                    .font(AppTypography.primary(size: 18, weight: .semibold))

                Spacer()
            }
            .padding(.horizontal, DesignTokens.horizontalPadding)
            .frame(height: 44)
            .background(PanelBackground(style: .header))

            TextField("Search cities or timezone IDs", text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($isSearchFocused)
                .padding(.horizontal, DesignTokens.horizontalPadding)
                .padding(.bottom, 10)

            PanelSeparator()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(results) { option in
                        Button {
                            model.addZone(option)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .font(AppTypography.primary(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text(option.timeZoneIdentifier)
                                    .font(AppTypography.secondary(
                                        size: 10,
                                        weight: .regular,
                                        relativeTo: .caption2
                                    ))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignTokens.horizontalPadding)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        PanelSeparator()
                            .padding(.leading, DesignTokens.horizontalPadding)
                    }
                }
            }
        }
        .frame(
            width: DesignTokens.panelWidth,
            height: DesignTokens.panelHeight(for: model.zones.count)
        )
        .background(PanelBackground(style: .content))
        .task {
            isSearchFocused = true
        }
    }
}
