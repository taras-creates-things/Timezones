import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppModel.self) private var model
    @State private var launchesAtLogin = LaunchAtLoginManager.isEnabled
    @State private var launchAtLoginError: String?
    @State private var scrollOffset: CGFloat = 0

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

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

        ZStack(alignment: .top) {
            settingsScrollView(
                appearance: $model.appearance,
                followsSystem: $model.followsSystemTimeZone,
                manualIdentifier: $model.manualHomeTimeZoneIdentifier
            )

            settingsHeader
        }
        .frame(
            width: DesignTokens.panelWidth,
            height: DesignTokens.panelHeight(for: model.zones.count)
        )
        .background(SettingsColors.surface(for: colorScheme))
    }

    private var settingsHeader: some View {
        HStack(spacing: 6) {
            backButton

            Text("Settings")
                .font(AppTypography.primary(size: 18, weight: .semibold))
                .foregroundStyle(SettingsColors.primary(for: colorScheme))

            Spacer()
        }
        .padding(.leading, 20)
        .padding(.trailing, 32)
        .padding(.top, 20)
        .padding(.bottom, 11)
        .frame(maxWidth: .infinity, minHeight: 59, maxHeight: 59)
        .background {
            settingsHeaderBackdrop
        }
    }

    private var settingsHeaderBackdrop: some View {
        let progress = min(max(scrollOffset / 16, 0), 1)

        return ZStack {
            if #unavailable(macOS 26.0) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask {
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }

            LinearGradient(
                colors: [
                    SettingsColors.surface(for: colorScheme),
                    SettingsColors.surface(for: colorScheme).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .opacity(progress)
        .allowsHitTesting(false)
    }

    private func settingsScrollView(
        appearance: Binding<AppearanceMode>,
        followsSystem: Binding<Bool>,
        manualIdentifier: Binding<String>
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 22) {
                appearanceSection(appearance: appearance)
                homeTimezoneSection(
                    followsSystem: followsSystem,
                    manualIdentifier: manualIdentifier
                )

                VStack(spacing: 16) {
                    moreSection
                    attribution
                }
            }
            .frame(width: SettingsMetrics.contentWidth)
            .padding(.top, 67)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SettingsScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("SettingsScrollView")).minY
                    )
                }
            }
            .background(ScrollIndicatorHider())
        }
        .coordinateSpace(name: "SettingsScrollView")
        .scrollIndicators(.hidden, axes: .vertical)
        .modifier(SettingsScrollEdgeEffect())
        .modifier(SettingsScrollOffsetObserver(offset: $scrollOffset))
    }

    private func appearanceSection(
        appearance: Binding<AppearanceMode>
    ) -> some View {
        SettingsSection("Appearance") {
            SettingsCard {
                SettingsRow(icon: "SettingsTheme", title: "Theme") {
                    ThemeSelector(selection: appearance)
                }

                SettingsDivider()

                SettingsRow(icon: "SettingsClock", title: "Use 24-hour time") {
                    Toggle("Use 24-hour time", isOn: Binding(
                        get: { model.uses24HourTime },
                        set: { model.uses24HourTime = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(SettingsSwitchToggleStyle())
                    .accessibilityLabel("Use 24-hour time")
                }

                SettingsDivider()

                SettingsRow(icon: "SettingsSoundEffects", title: "Sound effects") {
                    Toggle("Sound effects", isOn: Binding(
                        get: { model.soundEffectsEnabled },
                        set: { model.soundEffectsEnabled = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(SettingsSwitchToggleStyle())
                    .accessibilityLabel("Sound effects")
                }

                SettingsDivider()

                SettingsRow(icon: "SettingsLaunch", title: "Launch at login") {
                    Toggle("Launch at login", isOn: $launchesAtLogin)
                        .labelsHidden()
                        .toggleStyle(SettingsSwitchToggleStyle())
                        .accessibilityLabel("Launch at login")
                        .onChange(of: launchesAtLogin) { oldValue, newValue in
                            updateLaunchAtLogin(from: oldValue, to: newValue)
                        }
                }

                if let launchAtLoginError {
                    SettingsDivider()

                    Text(launchAtLoginError)
                        .font(AppTypography.primary(size: 11))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
        }
    }

    private func homeTimezoneSection(
        followsSystem: Binding<Bool>,
        manualIdentifier: Binding<String>
    ) -> some View {
        SettingsSection("Home timezone") {
            SettingsCard {
                SettingsRow(icon: "SettingsLaptop", title: "Follow Mac timezone") {
                    Toggle("Follow Mac timezone", isOn: followsSystem)
                        .labelsHidden()
                        .toggleStyle(SettingsSwitchToggleStyle())
                        .accessibilityLabel("Follow Mac timezone")
                }

                if !followsSystem.wrappedValue {
                    SettingsDivider()

                    SettingsRow(icon: "SettingsHomeCity", title: "Home city") {
                        ManualHomeTimeZoneMenu(
                            selection: manualIdentifier,
                            options: homeZoneOptions
                        )
                    }
                }
            }
        }
    }

    private var moreSection: some View {
        SettingsSection("More") {
            SettingsCard {
                SettingsRow(icon: "SettingsAppLogo", title: "Version") {
                    Text(appVersion)
                        .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                }

                SettingsDivider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    SettingsRow(icon: "SettingsCritical", title: "Critical action") {
                        Text("Log out")
                            .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                    }
                }
                .buttonStyle(.plain)
                .help("Quit Timezones")
                .accessibilityLabel("Quit Timezones")
            }
        }
    }

    private var attribution: some View {
        HStack(spacing: 3) {
            Text("BUILT BY")
            Text("TARAS DONCHENKO")
                .underline()
        }
        .font(AppTypography.secondary(size: 8, relativeTo: .caption2))
        .tracking(0.32)
        .foregroundStyle(SettingsColors.secondary(for: colorScheme))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Built by Taras Donchenko")
    }

    private var backButton: some View {
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

private struct SettingsSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
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
                .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                .frame(height: 17, alignment: .leading)
                .padding(.horizontal, 4)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SettingsColors.card(for: colorScheme))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SettingsRow<Accessory: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    @ViewBuilder let accessory: Accessory

    init(
        icon: String,
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.icon = icon
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(SettingsColors.primary(for: colorScheme))

            Text(title)
                .font(AppTypography.primary(size: 14, weight: .medium))
                .foregroundStyle(SettingsColors.primary(for: colorScheme))
                .lineLimit(1)

            Spacer(minLength: 8)

            accessory
                .font(AppTypography.primary(size: 14))
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
        .contentShape(Rectangle())
    }
}

private struct SettingsDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(SettingsColors.divider(for: colorScheme))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

private struct ManualHomeTimeZoneMenu: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: String
    let options: [TimeZoneOption]
    @State private var isHovering = false

    private var selectedLabel: String {
        TimeZoneSettingsLabel.text(
            city: TimeZoneSearchIndex.displayName(for: selection),
            timeZoneIdentifier: selection
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SettingsColors.pickerBackground(
                    for: colorScheme,
                    isHovered: isHovering
                ))

            visibleLabel
                .allowsHitTesting(false)

            HomeTimeZonePopUpButton(
                selection: $selection,
                options: options
            )
            .frame(width: 101, height: 28)
        }
            .frame(width: 101, height: 28)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onHover { isHovering = $0 }
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .accessibilityLabel("Home city")
            .accessibilityValue(selectedLabel)
    }

    private var visibleLabel: some View {
        HStack(spacing: 0) {
            Text(selectedLabel)
                .font(AppTypography.primary(size: 14, weight: .medium))
                .foregroundStyle(SettingsColors.primary(for: colorScheme))
                .lineLimit(1)

            Image("SettingsChevronDown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(SettingsColors.secondary(for: colorScheme))
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(width: 101, height: 28, alignment: .trailing)
    }
}

private struct HomeTimeZonePopUpButton: NSViewRepresentable {
    @Binding var selection: String
    let options: [TimeZoneOption]

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, options: options)
    }

    func makeNSView(context: Context) -> InvisiblePopUpButton {
        let button = InvisiblePopUpButton(frame: .zero, pullsDown: false)
        button.isBordered = false
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        button.setAccessibilityLabel("Home city")
        return button
    }

    func updateNSView(_ button: InvisiblePopUpButton, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.options = options

        let labels = options.map { option in
            TimeZoneSettingsLabel.text(
                city: option.label,
                timeZoneIdentifier: option.timeZoneIdentifier
            )
        }

        if button.itemTitles != labels {
            button.removeAllItems()
            button.addItems(withTitles: labels)
        }

        if let selectedIndex = options.firstIndex(where: {
            $0.timeZoneIdentifier == selection
        }) {
            button.selectItem(at: selectedIndex)
        }

        button.setAccessibilityValue(
            TimeZoneSettingsLabel.text(
                city: TimeZoneSearchIndex.displayName(for: selection),
                timeZoneIdentifier: selection
            )
        )
    }

    @MainActor
    final class Coordinator: NSObject {
        var selection: Binding<String>
        var options: [TimeZoneOption]

        init(selection: Binding<String>, options: [TimeZoneOption]) {
            self.selection = selection
            self.options = options
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            let selectedIndex = sender.indexOfSelectedItem
            guard options.indices.contains(selectedIndex) else { return }
            selection.wrappedValue = options[selectedIndex].timeZoneIdentifier
        }
    }
}

private final class InvisiblePopUpButton: NSPopUpButton {
    override func draw(_ dirtyRect: NSRect) {}
}

private struct ThemeSelector: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: AppearanceMode

    private var effectiveSelection: AppearanceMode {
        if selection == .system {
            return colorScheme == .dark ? .dark : .light
        }
        return selection
    }

    var body: some View {
        HStack(spacing: 0) {
            themeButton(.light)
            themeButton(.dark)
        }
        .padding(2)
        .background(SettingsColors.segmentTrack(for: colorScheme), in: Capsule())
    }

    private func themeButton(_ appearance: AppearanceMode) -> some View {
        let isSelected = effectiveSelection == appearance

        return Button {
            selection = appearance
        } label: {
            Text(appearance.label)
                .font(AppTypography.primary(
                    size: 14,
                    weight: isSelected ? .medium : .regular
                ))
                .foregroundStyle(SettingsColors.segmentText(
                    for: colorScheme,
                    isSelected: isSelected
                ))
                .padding(.horizontal, 12)
                .frame(height: 24)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(SettingsColors.segmentSelection(for: colorScheme))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SettingsSwitchToggleStyle: ToggleStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var transition: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .spring(response: 0.26, dampingFraction: 0.82, blendDuration: 0.08)
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(transition) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        configuration.isOn
                            ? Color("AccentColor")
                            : SettingsColors.switchTrack(for: colorScheme)
                    )

                Capsule()
                    .fill(SettingsColors.switchThumb(for: colorScheme))
                    .frame(width: 40, height: 24)
                    .padding(2)
                    .offset(x: configuration.isOn ? 20 : 0)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.24 : 0.12),
                        radius: 1,
                        y: 1
                    )
            }
            .frame(width: 64, height: 28)
            .contentShape(Capsule())
        }
        .buttonStyle(SettingsSwitchButtonStyle(reduceMotion: reduceMotion))
        .animation(transition, value: configuration.isOn)
    }
}

private struct SettingsSwitchButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.01)
                    : .easeOut(duration: 0.10),
                value: configuration.isPressed
            )
    }
}

private struct SettingsScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SettingsScrollEdgeEffect: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            content
        }
    }
}

private struct SettingsScrollOffsetObserver: ViewModifier {
    @Binding var offset: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.onScrollGeometryChange(
                for: CGFloat.self,
                of: { geometry in
                    max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                },
                action: { _, newOffset in
                    offset = newOffset
                }
            )
        } else {
            content.onPreferenceChange(SettingsScrollOffsetPreferenceKey.self) { minY in
                offset = max(0, -minY)
            }
        }
    }
}

struct ScrollIndicatorHider: NSViewRepresentable {
    func makeNSView(context: Context) -> ScrollIndicatorHidingView {
        ScrollIndicatorHidingView()
    }

    func updateNSView(_ nsView: ScrollIndicatorHidingView, context: Context) {
        nsView.hideIndicators()
    }
}

final class ScrollIndicatorHidingView: NSView {
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        hideIndicators()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hideIndicators()
    }

    func hideIndicators() {
        DispatchQueue.main.async { [weak self] in
            var ancestor = self?.superview

            while let view = ancestor {
                if let scrollView = view as? NSScrollView {
                    scrollView.scrollerStyle = .overlay
                    scrollView.hasVerticalScroller = false
                    scrollView.hasHorizontalScroller = false
                    scrollView.verticalScroller = nil
                    scrollView.horizontalScroller = nil
                    scrollView.autohidesScrollers = true
                    scrollView.tile()
                    scrollView.needsLayout = true
                    scrollView.layoutSubtreeIfNeeded()
                    return
                }

                ancestor = view.superview
            }
        }
    }
}

enum SettingsColors {
    static let editingAccent = Color(red: 0.918, green: 0.506, blue: 0.204)

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.106, green: 0.114, blue: 0.125)
            : Color(red: 0.965, green: 0.970, blue: 0.978)
    }

    static func card(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color.black.opacity(0.045)
    }

    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.922, green: 0.929, blue: 0.949)
            : Color(red: 0.106, green: 0.114, blue: 0.125)
    }

    static func secondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.431, green: 0.455, blue: 0.486)
            : Color(red: 0.38, green: 0.40, blue: 0.44)
    }

    static func divider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.10)
    }

    static func segmentTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.212, green: 0.220, blue: 0.227)
            : Color.black.opacity(0.08)
    }

    static func pickerBackground(
        for colorScheme: ColorScheme,
        isHovered: Bool
    ) -> Color {
        if colorScheme == .dark {
            return isHovered
                ? Color(red: 0.259, green: 0.271, blue: 0.286)
                : Color(red: 0.212, green: 0.220, blue: 0.227)
        }

        return Color.black.opacity(isHovered ? 0.13 : 0.08)
    }

    static func segmentSelection(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.176, green: 0.188, blue: 0.204)
    }

    static func segmentText(for colorScheme: ColorScheme, isSelected: Bool) -> Color {
        guard isSelected else { return primary(for: colorScheme) }
        return colorScheme == .dark
            ? Color(red: 0.176, green: 0.188, blue: 0.204)
            : .white
    }

    static func switchTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.235, green: 0.247, blue: 0.263)
            : Color(red: 0.78, green: 0.80, blue: 0.83)
    }

    static func switchThumb(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.99, green: 0.99, blue: 1)
    }

}

private enum SettingsMetrics {
    static let horizontalInset: CGFloat = 20
    static let contentWidth = DesignTokens.panelWidth - horizontalInset * 2
}

private enum TimeZoneSettingsLabel {
    private static let countryCodes: [String: String] = [
        "Africa/Cairo": "EG",
        "Africa/Johannesburg": "ZA",
        "Africa/Nairobi": "KE",
        "America/Chicago": "US",
        "America/Denver": "US",
        "America/Los_Angeles": "US",
        "America/Mexico_City": "MX",
        "America/New_York": "US",
        "America/Sao_Paulo": "BR",
        "America/Toronto": "CA",
        "America/Vancouver": "CA",
        "Asia/Dubai": "AE",
        "Asia/Hong_Kong": "HK",
        "Asia/Kolkata": "IN",
        "Asia/Seoul": "KR",
        "Asia/Singapore": "SG",
        "Asia/Tokyo": "JP",
        "Australia/Melbourne": "AU",
        "Australia/Sydney": "AU",
        "Europe/Berlin": "DE",
        "Europe/Dublin": "IE",
        "Europe/Istanbul": "TR",
        "Europe/Kyiv": "UA",
        "Europe/Lisbon": "PT",
        "Europe/London": "GB",
        "Europe/Paris": "FR",
        "Europe/Warsaw": "PL",
        "Pacific/Auckland": "NZ",
        "Pacific/Honolulu": "US"
    ]

    static func text(city: String, timeZoneIdentifier: String) -> String {
        guard let countryCode = countryCodes[timeZoneIdentifier] else { return city }
        return "\(city), \(countryCode)"
    }
}
