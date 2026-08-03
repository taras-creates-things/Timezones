import AppKit
import SwiftUI

struct TimezonesPanel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if let editingZoneID = model.editingZoneID,
               let zone = model.zones.first(where: { $0.id == editingZoneID }) {
                EditZoneView(zone: zone)
                    .id(zone.id)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if model.isAddingZone {
                AddZoneView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if model.isShowingSettings {
                SettingsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    MainPanel(now: timeline.date)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .preferredColorScheme(model.appearance.colorScheme)
        .animation(.snappy(duration: 0.22), value: model.isAddingZone)
        .animation(.snappy(duration: 0.22), value: model.isShowingSettings)
        .animation(.snappy(duration: 0.22), value: model.editingZoneID)
        .onAppear {
            applyAppAppearance(model.appearance)
        }
        .onChange(of: model.appearance) { _, appearance in
            applyAppAppearance(appearance)
        }
    }

    private func applyAppAppearance(_ appearance: AppearanceMode) {
        NSApplication.shared.appearance = appearance.appKitAppearance
    }
}

private struct MainPanel: View {
    @Environment(AppModel.self) private var model
    let now: Date

    private var selectedDate: Date {
        model.selectedDate(relativeTo: now)
    }

    private var homeZone: TrackedZone {
        TrackedZone(
            label: model.homeLabel,
            timeZoneIdentifier: model.homeTimeZone.identifier
        )
    }

    private var listHeight: CGFloat {
        if model.zones.isEmpty { return 92 }
        let visibleRows = min(model.zones.count, DesignTokens.maximumVisibleRows)
        return CGFloat(visibleRows) * DesignTokens.rowHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                TimelineRulerView(
                    selectedDate: selectedDate,
                    homeTimeZone: model.homeTimeZone,
                    timelineOffset: model.timelineOffset,
                    onOffsetChange: model.setTimelineOffset,
                    onInteractionEnded: model.finishTimelineInteraction
                )

                ZoneRowView(
                    zone: homeZone,
                    selectedDate: selectedDate,
                    homeTimeZone: model.homeTimeZone,
                    uses24HourTime: model.uses24HourTime,
                    isHome: true
                )
            }
            .background(PanelBackground(style: .header))

            PanelSeparator()

            if model.zones.isEmpty {
                ContentUnavailableView(
                    "No timezones",
                    systemImage: "globe",
                    description: Text("Add a city to start comparing time.")
                )
                .frame(height: listHeight)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(model.zones.enumerated()), id: \.element.id) { index, zone in
                            ZoneRowView(
                                zone: zone,
                                selectedDate: selectedDate,
                                homeTimeZone: model.homeTimeZone,
                                uses24HourTime: model.uses24HourTime,
                                canMoveUp: index > 0,
                                canMoveDown: index < model.zones.count - 1,
                                onMoveUp: { model.moveZone(id: zone.id, direction: -1) },
                                onMoveDown: { model.moveZone(id: zone.id, direction: 1) },
                                onEdit: { model.beginEditingZone(id: zone.id) },
                                onRemove: { model.removeZone(id: zone.id) }
                            )
                            .draggable(zone.id.uuidString)
                            .dropDestination(for: String.self) { droppedItems, _ in
                                guard let identifier = droppedItems.first,
                                      let droppedID = UUID(uuidString: identifier) else { return false }
                                withAnimation(.snappy(duration: 0.2)) {
                                    model.moveZone(id: droppedID, before: zone.id)
                                }
                                return true
                            }
                            .overlay(alignment: .bottom) {
                                if index < model.zones.count - 1 {
                                    PanelSeparator()
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(height: listHeight)
            }

            PanelSeparator()

            PanelFooterView()
        }
        .frame(width: DesignTokens.panelWidth)
        .background(PanelBackground())
    }
}
