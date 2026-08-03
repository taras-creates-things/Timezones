import SwiftUI

struct EditZoneView: View {
    @Environment(AppModel.self) private var model
    @State private var draft: TrackedZone

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

                Text("Edit timezone")
                    .font(.headline)

                Spacer()

                Button("Save", systemImage: "checkmark") {
                    draft.label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
                    model.updateZone(draft)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!isValid)
            }
            .padding(.horizontal, DesignTokens.horizontalPadding)
            .frame(height: 44)
            .background(PanelBackground(style: .header))

            PanelSeparator()

            Form {
                Section("Display") {
                    TextField("Name", text: $draft.label)
                    LabeledContent("Timezone", value: draft.timeZoneIdentifier)
                }

                Section("Working hours") {
                    Picker("Starts", selection: $draft.workSchedule.startMinute) {
                        timeOptions
                    }
                    Picker("Ends", selection: $draft.workSchedule.endMinute) {
                        timeOptions
                    }
                    Picker("Wrapping up", selection: $draft.workSchedule.wrappingMinutes) {
                        ForEach(wrappingOptions, id: \.self) { minutes in
                            Text(minutes == 0 ? "Off" : "Last \(minutes) min").tag(minutes)
                        }
                    }
                }

                Section("Working days") {
                    HStack(spacing: 5) {
                        ForEach(weekdays, id: \.0) { weekday, shortLabel, fullLabel in
                            Toggle(
                                shortLabel,
                                isOn: weekdayBinding(weekday)
                            )
                            .toggleStyle(.button)
                            .controlSize(.small)
                            .help(fullLabel)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: DesignTokens.panelWidth, height: 460)
        .background(PanelBackground(style: .content))
    }

    @ViewBuilder
    private var timeOptions: some View {
        ForEach(0..<48, id: \.self) { index in
            let minute = index * 30
            Text(String(format: "%02d:%02d", minute / 60, minute % 60)).tag(minute)
        }
    }

    private func weekdayBinding(_ weekday: Int) -> Binding<Bool> {
        Binding(
            get: { draft.workSchedule.workingWeekdays.contains(weekday) },
            set: { isEnabled in
                if isEnabled {
                    draft.workSchedule.workingWeekdays.insert(weekday)
                } else {
                    draft.workSchedule.workingWeekdays.remove(weekday)
                }
            }
        )
    }
}
