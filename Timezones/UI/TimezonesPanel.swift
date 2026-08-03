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
    @State private var draggedZoneID: TrackedZone.ID?
    @State private var dragStartIndex = 0
    @State private var dragTargetIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragLifted = false

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
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.regularMaterial)
                                    .padding(.horizontal, 4)
                                    .opacity(draggedZoneID == zone.id ? 1 : 0)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.primary.opacity(0.13), lineWidth: 1)
                                    .padding(.horizontal, 4)
                                    .opacity(draggedZoneID == zone.id ? 1 : 0)
                            }
                            .overlay(alignment: .bottom) {
                                if index < model.zones.count - 1 {
                                    PanelSeparator()
                                }
                            }
                            .scaleEffect(draggedZoneID == zone.id && isDragLifted ? 1.015 : 1)
                            .shadow(
                                color: .black.opacity(draggedZoneID == zone.id && isDragLifted ? 0.22 : 0),
                                radius: draggedZoneID == zone.id && isDragLifted ? 14 : 0,
                                x: 0,
                                y: draggedZoneID == zone.id && isDragLifted ? 6 : 0
                            )
                            .animation(.easeOut(duration: 0.14), value: isDragLifted)
                            .offset(y: rowOffset(for: zone.id, at: index))
                            .animation(
                                draggedZoneID == zone.id ? nil : .snappy(duration: 0.2),
                                value: dragTargetIndex
                            )
                            .zIndex(draggedZoneID == zone.id ? 10 : 0)
                            .contentShape(Rectangle())
                            .gesture(reorderGesture(for: zone))
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

    private func reorderGesture(for zone: TrackedZone) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                updateDrag(for: zone, translation: value.translation.height)
            }
            .onEnded { _ in
                settleDraggedZone()
            }
    }

    private func updateDrag(for zone: TrackedZone, translation: CGFloat) {
        guard !model.zones.isEmpty else { return }

        if draggedZoneID == nil {
            guard let startingIndex = model.zones.firstIndex(where: { $0.id == zone.id }) else { return }
            draggedZoneID = zone.id
            dragStartIndex = startingIndex
            dragTargetIndex = startingIndex
            dragOffset = 0
            withAnimation(.easeOut(duration: 0.14)) {
                isDragLifted = true
            }
        }

        guard draggedZoneID == zone.id else { return }

        let rowHeight = DesignTokens.rowHeight
        let threshold = rowHeight * 0.58
        var targetIndex = dragTargetIndex

        while targetIndex < model.zones.index(before: model.zones.endIndex),
              translation - CGFloat(targetIndex - dragStartIndex) * rowHeight > threshold {
            targetIndex += 1
        }

        while targetIndex > model.zones.startIndex,
              translation - CGFloat(targetIndex - dragStartIndex) * rowHeight < -threshold {
            targetIndex -= 1
        }

        dragOffset = translation
        dragTargetIndex = targetIndex
    }

    private func settleDraggedZone() {
        guard let settlingZoneID = draggedZoneID else { return }

        let destinationOffset = CGFloat(dragTargetIndex - dragStartIndex) * DesignTokens.rowHeight
        let destinationIndex = dragTargetIndex

        withAnimation(
            .snappy(duration: 0.24),
            completionCriteria: .removed
        ) {
            dragOffset = destinationOffset
            isDragLifted = false
        } completion: {
            guard draggedZoneID == settlingZoneID else { return }

            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                model.moveZone(id: settlingZoneID, toIndex: destinationIndex)
                draggedZoneID = nil
                dragOffset = 0
                dragStartIndex = destinationIndex
                dragTargetIndex = destinationIndex
            }
        }
    }

    private func rowOffset(for zoneID: TrackedZone.ID, at index: Int) -> CGFloat {
        guard let draggedZoneID else { return 0 }
        if zoneID == draggedZoneID { return dragOffset }

        if dragTargetIndex > dragStartIndex,
           index > dragStartIndex,
           index <= dragTargetIndex {
            return -DesignTokens.rowHeight
        }

        if dragTargetIndex < dragStartIndex,
           index >= dragTargetIndex,
           index < dragStartIndex {
            return DesignTokens.rowHeight
        }

        return 0
    }
}
