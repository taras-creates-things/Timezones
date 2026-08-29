import SwiftUI

struct AddZoneView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool

    private var results: [TimeZoneOption] {
        TimeZoneSearchIndex.search(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
            resultsList
        }
        .frame(
            width: DesignTokens.panelWidth,
            height: DesignTokens.panelHeight(for: model.zones.count)
        )
        .background(SettingsColors.surface(for: colorScheme))
        .task {
            isSearchFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button {
                model.showMainPanel()
            } label: {
                Image("SettingsBack")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Back")
            .accessibilityLabel("Back")

            Text("Add timezone")
                .font(AppTypography.primary(size: 18, weight: .semibold))
                .foregroundStyle(SettingsColors.primary(for: colorScheme))

            Spacer()
        }
        .padding(.leading, 20)
        .padding(.trailing, 32)
        .padding(.top, 20)
        .padding(.bottom, 11)
        .frame(maxWidth: .infinity, minHeight: 59, maxHeight: 59)
    }

    private var searchField: some View {
        HStack(spacing: 4) {
            Image("AddZoneSearch")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(SettingsColors.secondary(for: colorScheme))

            TextField(
                "",
                text: $query,
                prompt: Text("Search cities or timezones IDs...")
                    .foregroundStyle(SettingsColors.secondary(for: colorScheme))
            )
            .textFieldStyle(.plain)
            .font(AppTypography.primary(size: 14, weight: .medium))
            .foregroundStyle(SettingsColors.primary(for: colorScheme))
            .tint(SettingsColors.editingAccent)
            .focused($isSearchFocused)
        }
        .padding(8)
        .frame(height: 36)
        .background {
            Capsule()
                .fill(SettingsColors.card(for: colorScheme))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private var resultsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, option in
                    AddZoneResultRow(
                        option: option,
                        showsDivider: index < results.count - 1
                    ) {
                        model.addZone(option)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(ScrollIndicatorHider())
        }
        .scrollIndicators(.hidden, axes: .vertical)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SettingsColors.card(for: colorScheme))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
}

private struct AddZoneResultRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let option: TimeZoneOption
    let showsDivider: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .foregroundStyle(SettingsColors.primary(for: colorScheme))

                    Text(option.timeZoneIdentifier.replacingOccurrences(of: "_", with: " "))
                        .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                }
                .font(AppTypography.primary(size: 14, weight: .medium))
                .frame(height: 36, alignment: .leading)

                Spacer(minLength: 8)

                if isHovering {
                    Image("AddZonePlus")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(SettingsColors.primary(for: colorScheme))
                        .padding(4)
                        .overlay {
                            Circle()
                                .stroke(
                                    SettingsColors.divider(for: colorScheme),
                                    lineWidth: 0.5
                                )
                        }
                        .transition(.scale(scale: 0.82).combined(with: .opacity))
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, isHovering ? 16 : 12)
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle()
                        .fill(SettingsColors.divider(for: colorScheme))
                        .frame(height: 0.5)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(
                reduceMotion
                    ? .linear(duration: 0.01)
                    : .easeOut(duration: 0.12)
            ) {
                isHovering = hovering
            }
        }
        .accessibilityLabel("Add \(option.label) timezone")
        .help("Add \(option.label)")
    }
}
