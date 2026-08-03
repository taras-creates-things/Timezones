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
                    .font(.headline)

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

            List(results) { option in
                Button {
                    model.addZone(option)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.label)
                            .foregroundStyle(.primary)
                        Text(option.timeZoneIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: DesignTokens.panelWidth, height: 410)
        .background(PanelBackground(style: .content))
        .task {
            isSearchFocused = true
        }
    }
}
