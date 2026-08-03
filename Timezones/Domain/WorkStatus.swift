import Foundation

enum WorkStatus: String, Sendable {
    case working
    case wrappingUp
    case beforeWork
    case night
    case weekend

    var label: String {
        switch self {
        case .working: "Working"
        case .wrappingUp: "Wrapping up"
        case .beforeWork: "Before work"
        case .night: "Night"
        case .weekend: "Weekend"
        }
    }

    var systemImage: String {
        switch self {
        case .working: "circle.fill"
        case .wrappingUp: "circle.fill"
        case .beforeWork: "sunrise.fill"
        case .night: "moon.fill"
        case .weekend: "cup.and.saucer.fill"
        }
    }
}

enum WorkStatusEngine {
    static func status(for date: Date, in timeZone: TimeZone, schedule: WorkSchedule) -> WorkStatus {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let weekday = components.weekday ?? 1
        guard schedule.workingWeekdays.contains(weekday) else { return .weekend }

        let minuteOfDay = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if minuteOfDay >= schedule.startMinute && minuteOfDay < schedule.endMinute {
            if minuteOfDay >= schedule.endMinute - schedule.wrappingMinutes {
                return .wrappingUp
            }
            return .working
        }

        if minuteOfDay >= 5 * 60 && minuteOfDay < schedule.startMinute {
            return .beforeWork
        }
        return .night
    }
}
