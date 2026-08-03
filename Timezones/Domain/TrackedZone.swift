import Foundation

struct WorkSchedule: Codable, Hashable, Sendable {
    var workingWeekdays: Set<Int>
    var startMinute: Int
    var endMinute: Int
    var wrappingMinutes: Int

    static let standard = WorkSchedule(
        workingWeekdays: [2, 3, 4, 5, 6],
        startMinute: 9 * 60,
        endMinute: 17 * 60,
        wrappingMinutes: 60
    )
}

struct TrackedZone: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var label: String
    var timeZoneIdentifier: String
    var workSchedule: WorkSchedule

    init(
        id: UUID = UUID(),
        label: String,
        timeZoneIdentifier: String,
        workSchedule: WorkSchedule = .standard
    ) {
        self.id = id
        self.label = label
        self.timeZoneIdentifier = timeZoneIdentifier
        self.workSchedule = workSchedule
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }

    static let initialZones: [TrackedZone] = [
        TrackedZone(label: "San Francisco", timeZoneIdentifier: "America/Los_Angeles"),
        TrackedZone(label: "New York", timeZoneIdentifier: "America/New_York"),
        TrackedZone(label: "New Delhi", timeZoneIdentifier: "Asia/Kolkata")
    ]
}
