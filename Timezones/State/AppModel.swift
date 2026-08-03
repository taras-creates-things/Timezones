import Foundation
import Observation

enum AppearanceMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

@MainActor
@Observable
final class AppModel {
    static let maximumTimelineOffset: TimeInterval = 14 * 24 * 60 * 60
    static let snappingInterval: TimeInterval = 15 * 60

    var zones: [TrackedZone] {
        didSet { persistZones() }
    }

    var followsSystemTimeZone: Bool {
        didSet { defaults.set(followsSystemTimeZone, forKey: Keys.followsSystemTimeZone) }
    }

    var manualHomeTimeZoneIdentifier: String {
        didSet { defaults.set(manualHomeTimeZoneIdentifier, forKey: Keys.manualHomeTimeZoneIdentifier) }
    }

    var uses24HourTime: Bool {
        didSet { defaults.set(uses24HourTime, forKey: Keys.uses24HourTime) }
    }

    var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var timelineOffset: TimeInterval = 0
    var isAddingZone = false
    var isShowingSettings = false
    var editingZoneID: TrackedZone.ID?

    @ObservationIgnored
    private let defaults: UserDefaults

    @ObservationIgnored
    private var timelineAnimationTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let zoneData = defaults.data(forKey: Keys.zones),
           let decodedZones = try? JSONDecoder().decode([TrackedZone].self, from: zoneData) {
            zones = decodedZones
        } else {
            zones = TrackedZone.initialZones
        }

        if defaults.object(forKey: Keys.followsSystemTimeZone) == nil {
            followsSystemTimeZone = true
        } else {
            followsSystemTimeZone = defaults.bool(forKey: Keys.followsSystemTimeZone)
        }

        manualHomeTimeZoneIdentifier = defaults.string(forKey: Keys.manualHomeTimeZoneIdentifier)
            ?? TimeZone.autoupdatingCurrent.identifier

        if defaults.object(forKey: Keys.uses24HourTime) == nil {
            uses24HourTime = true
        } else {
            uses24HourTime = defaults.bool(forKey: Keys.uses24HourTime)
        }

        appearance = defaults.string(forKey: Keys.appearance)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .system
    }

    var homeTimeZone: TimeZone {
        if followsSystemTimeZone {
            return .autoupdatingCurrent
        }
        return TimeZone(identifier: manualHomeTimeZoneIdentifier) ?? .autoupdatingCurrent
    }

    var homeLabel: String {
        TimeZoneSearchIndex.displayName(for: homeTimeZone.identifier)
    }

    func selectedDate(relativeTo now: Date) -> Date {
        now.addingTimeInterval(timelineOffset)
    }

    func setTimelineOffset(_ proposedOffset: TimeInterval) {
        timelineAnimationTask?.cancel()
        timelineAnimationTask = nil
        applyTimelineOffset(proposedOffset)
    }

    private func applyTimelineOffset(_ proposedOffset: TimeInterval) {
        timelineOffset = min(
            max(proposedOffset, -Self.maximumTimelineOffset),
            Self.maximumTimelineOffset
        )
    }

    func finishTimelineInteraction() {
        let snapped = (timelineOffset / Self.snappingInterval).rounded() * Self.snappingInterval
        setTimelineOffset(abs(snapped) < Self.snappingInterval / 2 ? 0 : snapped)
    }

    func stepTimeline(by interval: TimeInterval) {
        setTimelineOffset(timelineOffset + interval)
        finishTimelineInteraction()
    }

    func resetToNow() {
        timelineAnimationTask?.cancel()
        timelineAnimationTask = nil
        applyTimelineOffset(0)
    }

    func animateTimelineToNow(duration: TimeInterval = 0.48) {
        timelineAnimationTask?.cancel()

        let startingOffset = timelineOffset
        guard abs(startingOffset) >= 1, duration > 0 else {
            resetToNow()
            return
        }

        let startedAt = ProcessInfo.processInfo.systemUptime
        timelineAnimationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
                let progress = min(max(elapsed / duration, 0), 1)
                let easedProgress = 1 - pow(1 - progress, 3)

                self?.applyTimelineOffset(startingOffset * (1 - easedProgress))

                if progress >= 1 { break }
                try? await Task.sleep(nanoseconds: 16_000_000)
            }

            guard !Task.isCancelled else { return }
            self?.applyTimelineOffset(0)
            self?.timelineAnimationTask = nil
        }
    }

    func addZone(_ option: TimeZoneOption) {
        zones.append(
            TrackedZone(label: option.label, timeZoneIdentifier: option.timeZoneIdentifier)
        )
        showMainPanel()
    }

    func beginEditingZone(id: TrackedZone.ID) {
        isAddingZone = false
        isShowingSettings = false
        editingZoneID = id
    }

    func updateZone(_ updatedZone: TrackedZone) {
        guard let index = zones.firstIndex(where: { $0.id == updatedZone.id }) else { return }
        zones[index] = updatedZone
        showMainPanel()
    }

    func showAddZone() {
        editingZoneID = nil
        isShowingSettings = false
        isAddingZone = true
    }

    func showSettings() {
        editingZoneID = nil
        isAddingZone = false
        isShowingSettings = true
    }

    func showMainPanel() {
        editingZoneID = nil
        isAddingZone = false
        isShowingSettings = false
    }

    func removeZone(id: TrackedZone.ID) {
        zones.removeAll { $0.id == id }
    }

    func moveZone(id: TrackedZone.ID, direction: Int) {
        guard let currentIndex = zones.firstIndex(where: { $0.id == id }) else { return }
        let destination = currentIndex + direction
        guard zones.indices.contains(destination) else { return }
        zones.swapAt(currentIndex, destination)
    }

    func moveZone(id: TrackedZone.ID, before destinationID: TrackedZone.ID) {
        guard id != destinationID,
              let sourceIndex = zones.firstIndex(where: { $0.id == id }),
              let destinationIndex = zones.firstIndex(where: { $0.id == destinationID }) else { return }

        let zone = zones.remove(at: sourceIndex)
        let adjustedDestination = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        zones.insert(zone, at: adjustedDestination)
    }

    private func persistZones() {
        guard let data = try? JSONEncoder().encode(zones) else { return }
        defaults.set(data, forKey: Keys.zones)
    }

    private enum Keys {
        static let zones = "trackedZones"
        static let followsSystemTimeZone = "followsSystemTimeZone"
        static let manualHomeTimeZoneIdentifier = "manualHomeTimeZoneIdentifier"
        static let uses24HourTime = "uses24HourTime"
        static let appearance = "appearance"
    }
}
