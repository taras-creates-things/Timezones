import AppKit
import SwiftUI

struct EditZoneView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppModel.self) private var model
    @State private var draft: TrackedZone
    @State private var scrollOffset: CGFloat = 0
    @State private var isEditingName = false
    @State private var nameBeforeEditing = ""
    @FocusState private var isNameFocused: Bool

    private let wrappingOptions = [0, 30, 60, 90, 120]
    private let weekdays = [
        (2, "M", "Monday"),
        (3, "T", "Tuesday"),
        (4, "W", "Wednesday"),
        (5, "T", "Thursday"),
        (6, "F", "Friday"),
        (7, "S", "Saturday"),
        (1, "S", "Sunday")
    ]

    init(zone: TrackedZone) {
        _draft = State(initialValue: zone)
    }

    private var isValid: Bool {
        !draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.workSchedule.endMinute > draft.workSchedule.startMinute
            && !draft.workSchedule.workingWeekdays.isEmpty
    }

    private var formattedTimeZoneIdentifier: String {
        draft.timeZoneIdentifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " / ")
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
            header
        }
        .frame(
            width: DesignTokens.panelWidth,
            height: DesignTokens.panelHeight(for: model.zones.count)
        )
        .background(SettingsColors.surface(for: colorScheme))
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Button(action: discardChanges) {
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
                .help("Back without saving")
                .accessibilityLabel("Back without saving")

                Text("Edit timezone")
                    .font(AppTypography.primary(size: 18, weight: .semibold))
                    .foregroundStyle(SettingsColors.primary(for: colorScheme))
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Button("Discard", action: discardChanges)
                    .buttonStyle(EditZoneHeaderButtonStyle(
                        fill: SettingsColors.card(for: colorScheme)
                    ))

                Button("Save", action: saveChanges)
                    .buttonStyle(EditZoneHeaderButtonStyle(
                        fill: SettingsColors.editingAccent
                    ))
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.45)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 11)
        .frame(maxWidth: .infinity, minHeight: 59, maxHeight: 59)
        .background {
            headerBackdrop
        }
    }

    private var headerBackdrop: some View {
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

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 22) {
                displaySection
                workingHoursSection
                workingDaysSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 67)
            .padding(.bottom, 20)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: EditZoneScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("EditZoneScrollView")).minY
                    )
                }
            }
            .background(ScrollIndicatorHider())
        }
        .coordinateSpace(name: "EditZoneScrollView")
        .scrollIndicators(.hidden, axes: .vertical)
        .modifier(EditZoneScrollEdgeEffect())
        .modifier(EditZoneScrollOffsetObserver(offset: $scrollOffset))
    }

    private var displaySection: some View {
        EditZoneSection(title: "Display") {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        EditZoneFieldLabel("Name")

                        if isEditingName {
                            TextField("Name", text: $draft.label)
                                .textFieldStyle(.plain)
                                .font(AppTypography.primary(size: 14, weight: .medium))
                                .foregroundStyle(SettingsColors.primary(for: colorScheme))
                                .tint(SettingsColors.editingAccent)
                                .focused($isNameFocused)
                                .onSubmit(confirmNameEdit)
                                .onExitCommand(perform: cancelNameEdit)
                        } else {
                            Text(draft.label)
                                .font(AppTypography.primary(size: 14, weight: .medium))
                                .foregroundStyle(SettingsColors.primary(for: colorScheme))
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: beginNameEdit)

                    Spacer(minLength: 8)

                    if isEditingName {
                        HStack(spacing: 6) {
                            Button(action: cancelNameEdit) {
                                Image("EditZoneCancel")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                            .help("Discard name change")
                            .accessibilityLabel("Discard name change")

                            Button(action: confirmNameEdit) {
                                Image("EditZoneConfirm")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(SettingsColors.primary(for: colorScheme))
                            }
                            .buttonStyle(.plain)
                            .disabled(draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(
                                draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? 0.45
                                    : 1
                            )
                            .help("Confirm name change")
                            .accessibilityLabel("Confirm name change")
                        }
                    } else {
                        Button(action: beginNameEdit) {
                            Image("EditZonePencil")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(SettingsColors.primary(for: colorScheme))
                        }
                        .buttonStyle(.plain)
                        .help("Edit name")
                        .accessibilityLabel("Edit timezone name")
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .frame(height: 55)
                .contentShape(Rectangle())

                EditZoneDivider()

                VStack(alignment: .leading, spacing: 4) {
                    EditZoneFieldLabel("Timezone")

                    Text(formattedTimeZoneIdentifier)
                        .font(AppTypography.primary(size: 14, weight: .medium))
                        .foregroundStyle(SettingsColors.primary(for: colorScheme))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55, alignment: .leading)
            }
        }
    }

    private var workingHoursSection: some View {
        EditZoneSection(title: "Working hours") {
            VStack(spacing: 0) {
                EditZoneValueRow(title: "Starts") {
                    EditZoneValueMenu(
                        value: timeLabel(for: draft.workSchedule.startMinute),
                        selection: $draft.workSchedule.startMinute,
                        options: timeOptions,
                        accessibilityLabel: "Workday starts"
                    )
                }

                EditZoneDivider()

                EditZoneValueRow(title: "Ends") {
                    EditZoneValueMenu(
                        value: timeLabel(for: draft.workSchedule.endMinute),
                        selection: $draft.workSchedule.endMinute,
                        options: timeOptions,
                        accessibilityLabel: "Workday ends"
                    )
                }

                EditZoneDivider()

                EditZoneValueRow(title: "Wrapping up") {
                    EditZoneValueMenu(
                        value: wrappingLabel(for: draft.workSchedule.wrappingMinutes),
                        selection: $draft.workSchedule.wrappingMinutes,
                        options: wrappingMenuOptions,
                        accessibilityLabel: "Wrapping up period"
                    )
                }
            }
        }
    }

    private var workingDaysSection: some View {
        EditZoneSection(title: "Working days", showsCard: false) {
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.0) { weekday, shortLabel, fullLabel in
                    EditZoneDayButton(
                        shortLabel: shortLabel,
                        fullLabel: fullLabel,
                        isSelected: draft.workSchedule.workingWeekdays.contains(weekday)
                    ) {
                        if draft.workSchedule.workingWeekdays.contains(weekday) {
                            draft.workSchedule.workingWeekdays.remove(weekday)
                        } else {
                            draft.workSchedule.workingWeekdays.insert(weekday)
                        }
                    }
                }
            }
            .frame(height: 33)
        }
    }

    private var timeOptions: [EditZoneMenuOption] {
        (0..<48).map { index in
            let minute = index * 30
            return EditZoneMenuOption(value: minute, label: timeLabel(for: minute))
        }
    }

    private var wrappingMenuOptions: [EditZoneMenuOption] {
        wrappingOptions.map { minutes in
            EditZoneMenuOption(value: minutes, label: wrappingLabel(for: minutes))
        }
    }

    private func timeLabel(for minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    private func wrappingLabel(for minutes: Int) -> String {
        minutes == 0 ? "Off" : "Last \(minutes) min"
    }

    private func beginNameEdit() {
        guard !isEditingName else { return }
        nameBeforeEditing = draft.label
        isEditingName = true
        isNameFocused = true
    }

    private func cancelNameEdit() {
        draft.label = nameBeforeEditing
        isEditingName = false
        isNameFocused = false
    }

    private func confirmNameEdit() {
        let trimmedName = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        draft.label = trimmedName
        nameBeforeEditing = trimmedName
        isEditingName = false
        isNameFocused = false
    }

    private func discardChanges() {
        model.showMainPanel()
    }

    private func saveChanges() {
        guard isValid else { return }
        draft.label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        model.updateZone(draft)
    }
}

private struct EditZoneSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let showsCard: Bool
    @ViewBuilder let content: Content

    init(
        title: String,
        showsCard: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsCard = showsCard
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppTypography.secondary(size: 10, weight: .medium, relativeTo: .caption2))
                .tracking(0.4)
                .foregroundStyle(SettingsColors.secondary(for: colorScheme))
                .padding(.leading, 4)
                .padding(.trailing, 12)

            if showsCard {
                content
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(SettingsColors.card(for: colorScheme))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditZoneFieldLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(AppTypography.secondary(size: 10, weight: .medium, relativeTo: .caption2))
            .tracking(0.4)
            .foregroundStyle(SettingsColors.secondary(for: colorScheme))
            .lineLimit(1)
    }
}

private struct EditZoneValueRow<Accessory: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @ViewBuilder let accessory: Accessory

    init(title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(AppTypography.primary(size: 14, weight: .medium))
                .foregroundStyle(SettingsColors.primary(for: colorScheme))

            Spacer(minLength: 8)

            accessory
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 51, maxHeight: 51)
    }
}

private struct EditZoneMenuOption: Identifiable, Equatable {
    let value: Int
    let label: String

    var id: Int { value }
}

private struct EditZoneValueMenu: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    @Binding var selection: Int
    let options: [EditZoneMenuOption]
    let accessibilityLabel: String
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            Text(value)
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
        .frame(height: 28)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SettingsColors.pickerBackground(
                    for: colorScheme,
                    isHovered: isHovering
                ))
        }
        .overlay {
            EditZonePopUpButton(
                selection: $selection,
                options: options,
                accessibilityLabel: accessibilityLabel
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .fixedSize()
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(value)
    }
}

private struct EditZonePopUpButton: NSViewRepresentable {
    @Binding var selection: Int
    let options: [EditZoneMenuOption]
    let accessibilityLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, options: options)
    }

    func makeNSView(context: Context) -> EditZoneInvisiblePopUpButton {
        let button = EditZoneInvisiblePopUpButton(frame: .zero, pullsDown: false)
        button.isBordered = false
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        button.setAccessibilityLabel(accessibilityLabel)
        return button
    }

    func updateNSView(_ button: EditZoneInvisiblePopUpButton, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.options = options

        let labels = options.map(\.label)
        if button.itemTitles != labels {
            button.removeAllItems()
            button.addItems(withTitles: labels)
        }

        if let selectedIndex = options.firstIndex(where: { $0.value == selection }) {
            button.selectItem(at: selectedIndex)
        }

        button.setAccessibilityLabel(accessibilityLabel)
        button.setAccessibilityValue(
            options.first(where: { $0.value == selection })?.label ?? ""
        )
    }

    @MainActor
    final class Coordinator: NSObject {
        var selection: Binding<Int>
        var options: [EditZoneMenuOption]

        init(selection: Binding<Int>, options: [EditZoneMenuOption]) {
            self.selection = selection
            self.options = options
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            let selectedIndex = sender.indexOfSelectedItem
            guard options.indices.contains(selectedIndex) else { return }
            selection.wrappedValue = options[selectedIndex].value
        }
    }
}

private final class EditZoneInvisiblePopUpButton: NSPopUpButton {
    override func draw(_ dirtyRect: NSRect) {}
}

private struct EditZoneDayButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let shortLabel: String
    let fullLabel: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(
                reduceMotion
                    ? .linear(duration: 0.01)
                    : .easeOut(duration: 0.14)
            ) {
                action()
            }
        } label: {
            Text(shortLabel)
                .font(AppTypography.primary(size: 14, weight: .medium))
                .foregroundStyle(
                    isSelected
                        ? SettingsColors.primary(for: colorScheme)
                        : SettingsColors.secondary(for: colorScheme)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            isSelected
                                ? SettingsColors.card(for: colorScheme)
                                : Color.clear
                        )
                }
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SettingsColors.divider(for: colorScheme), lineWidth: 1)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(fullLabel)
        .accessibilityLabel(fullLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct EditZoneDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(SettingsColors.divider(for: colorScheme))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

private struct EditZoneScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct EditZoneScrollEdgeEffect: ViewModifier {
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

private struct EditZoneScrollOffsetObserver: ViewModifier {
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
            content.onPreferenceChange(EditZoneScrollOffsetPreferenceKey.self) { minY in
                offset = max(0, -minY)
            }
        }
    }
}

private struct EditZoneHeaderButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.primary(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background {
                Capsule()
                    .fill(fill)
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                reduceMotion
                    ? .linear(duration: 0.01)
                    : .easeOut(duration: 0.10),
                value: configuration.isPressed
            )
    }
}
