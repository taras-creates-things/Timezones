import Foundation

enum TimeEngine {
    static func timeString(for date: Date, in timeZone: TimeZone, uses24HourTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: uses24HourTime ? "en_GB" : "en_US")
        formatter.timeZone = timeZone
        formatter.dateFormat = uses24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    static func dateString(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date).uppercased()
    }

    static func abbreviation(for date: Date, in timeZone: TimeZone) -> String {
        if let pair = preferredAbbreviations[timeZone.identifier] {
            return timeZone.isDaylightSavingTime(for: date) ? pair.daylight : pair.standard
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "zzz"
        return formatter.string(from: date)
    }

    static func utcOffsetString(for date: Date, in timeZone: TimeZone) -> String {
        let totalMinutes = timeZone.secondsFromGMT(for: date) / 60
        guard totalMinutes != 0 else { return "UTC" }

        let sign = totalMinutes > 0 ? "+" : "−"
        let magnitude = abs(totalMinutes)
        return String(format: "UTC%@%02d:%02d", sign, magnitude / 60, magnitude % 60)
    }

    static func relativeOffsetString(for date: Date, zone: TimeZone, relativeTo homeZone: TimeZone) -> String {
        let seconds = zone.secondsFromGMT(for: date) - homeZone.secondsFromGMT(for: date)
        return relativeOffsetString(seconds: seconds)
    }

    static func relativeOffsetString(seconds: Int) -> String {
        guard seconds != 0 else { return "0H" }

        let sign = seconds > 0 ? "+" : "−"
        let magnitudeMinutes = abs(seconds) / 60
        let hours = magnitudeMinutes / 60
        let minutes = magnitudeMinutes % 60

        if minutes == 0 {
            return "\(sign)\(hours)H"
        }
        return "\(sign)\(hours)H \(minutes)M"
    }

    static func timelineOffsetString(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval.rounded()) / 60
        guard abs(totalMinutes) >= 1 else { return "NOW" }

        let sign = totalMinutes > 0 ? "+" : "−"
        let magnitude = abs(totalMinutes)
        let days = magnitude / (24 * 60)
        let hours = (magnitude % (24 * 60)) / 60
        let minutes = magnitude % 60

        var components: [String] = []
        if days > 0 { components.append("\(days)D") }
        if hours > 0 { components.append("\(hours)H") }
        if minutes > 0 { components.append("\(minutes)M") }
        return sign + components.joined(separator: " ")
    }

    static func relativeDayLabel(for date: Date, zone: TimeZone, relativeTo homeZone: TimeZone) -> String? {
        let homeDay = dayAnchor(for: date, in: homeZone)
        let zoneDay = dayAnchor(for: date, in: zone)
        let calendar = utcCalendar
        let dayDelta = calendar.dateComponents([.day], from: homeDay, to: zoneDay).day ?? 0

        switch dayDelta {
        case -1: return "YESTERDAY"
        case 1: return "TOMORROW"
        case 0: return nil
        default: return dateString(for: date, in: zone)
        }
    }

    private static func dayAnchor(for date: Date, in timeZone: TimeZone) -> Date {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = timeZone
        let components = localCalendar.dateComponents([.year, .month, .day], from: date)
        return utcCalendar.date(from: components) ?? date
    }

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private static let preferredAbbreviations: [String: (standard: String, daylight: String)] = [
        "America/Los_Angeles": ("PST", "PDT"),
        "America/Vancouver": ("PST", "PDT"),
        "America/New_York": ("EST", "EDT"),
        "America/Toronto": ("EST", "EDT"),
        "America/Chicago": ("CST", "CDT"),
        "America/Denver": ("MST", "MDT"),
        "America/Honolulu": ("HST", "HST"),
        "Europe/London": ("GMT", "BST"),
        "Europe/Dublin": ("GMT", "IST"),
        "Europe/Lisbon": ("WET", "WEST"),
        "Europe/Paris": ("CET", "CEST"),
        "Europe/Berlin": ("CET", "CEST"),
        "Europe/Warsaw": ("CET", "CEST"),
        "Europe/Kyiv": ("EET", "EEST"),
        "Europe/Istanbul": ("TRT", "TRT"),
        "Asia/Dubai": ("GST", "GST"),
        "Asia/Kolkata": ("IST", "IST"),
        "Asia/Singapore": ("SGT", "SGT"),
        "Asia/Hong_Kong": ("HKT", "HKT"),
        "Asia/Tokyo": ("JST", "JST"),
        "Asia/Seoul": ("KST", "KST"),
        "Australia/Sydney": ("AEST", "AEDT"),
        "Australia/Melbourne": ("AEST", "AEDT"),
        "Pacific/Auckland": ("NZST", "NZDT")
    ]
}
