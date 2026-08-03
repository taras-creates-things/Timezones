import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var launchesAtLogin = LaunchAtLoginManager.isEnabled
    @State private var launchAtLoginError: String?

    private var homeZoneOptions: [TimeZoneOption] {
        var seen = Set<String>()
        var options: [TimeZoneOption] = []
        let current = TimeZoneOption(
            label: TimeZoneSearchIndex.displayName(for: model.manualHomeTimeZoneIdentifier),
            timeZoneIdentifier: model.manualHomeTimeZoneIdentifier
        )

        for option in [current] + TimeZoneSearchIndex.featured {
            if seen.insert(option.timeZoneIdentifier).inserted {
                options.append(option)
            }
        }
        return options
    }

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    model.showMainPanel()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .help("Back")

                Text("Settings")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.horizontalPadding)
            .frame(height: 44)
            .background(PanelBackground(style: .header))

            PanelSeparator()

            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $model.appearance) {
                        ForEach(AppearanceMode.allCases) { appearance in
                            Text(appearance.label).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Use 24-hour time", isOn: $model.uses24HourTime)

                    Toggle("Launch at login", isOn: $launchesAtLogin)
                        .onChange(of: launchesAtLogin) { oldValue, newValue in
                            updateLaunchAtLogin(from: oldValue, to: newValue)
                        }

                    if let launchAtLoginError {
                        Text(launchAtLoginError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Home timezone") {
                    Toggle("Follow Mac timezone", isOn: $model.followsSystemTimeZone)

                    if !model.followsSystemTimeZone {
                        Picker("Timezone", selection: $model.manualHomeTimeZoneIdentifier) {
                            ForEach(homeZoneOptions) { option in
                                Text(option.label).tag(option.timeZoneIdentifier)
                            }
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "0.1.0")
                    Text("All timezone calculations happen locally on this Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Quit Timezones") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: DesignTokens.panelWidth, height: 450)
        .background(PanelBackground(style: .content))
    }

    private func updateLaunchAtLogin(from oldValue: Bool, to isEnabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(isEnabled)
            launchAtLoginError = nil
        } catch {
            launchesAtLogin = oldValue
            launchAtLoginError = "Couldn’t update launch at login: \(error.localizedDescription)"
        }
    }
}
