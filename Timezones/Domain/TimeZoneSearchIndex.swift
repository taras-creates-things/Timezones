import Foundation

struct TimeZoneOption: Identifiable, Hashable, Sendable {
    let label: String
    let timeZoneIdentifier: String

    var id: String { "\(label)|\(timeZoneIdentifier)" }
}

enum TimeZoneSearchIndex {
    static let featured: [TimeZoneOption] = [
        TimeZoneOption(label: "San Francisco", timeZoneIdentifier: "America/Los_Angeles"),
        TimeZoneOption(label: "Los Angeles", timeZoneIdentifier: "America/Los_Angeles"),
        TimeZoneOption(label: "Vancouver", timeZoneIdentifier: "America/Vancouver"),
        TimeZoneOption(label: "New York", timeZoneIdentifier: "America/New_York"),
        TimeZoneOption(label: "Toronto", timeZoneIdentifier: "America/Toronto"),
        TimeZoneOption(label: "Chicago", timeZoneIdentifier: "America/Chicago"),
        TimeZoneOption(label: "Denver", timeZoneIdentifier: "America/Denver"),
        TimeZoneOption(label: "Mexico City", timeZoneIdentifier: "America/Mexico_City"),
        TimeZoneOption(label: "São Paulo", timeZoneIdentifier: "America/Sao_Paulo"),
        TimeZoneOption(label: "London", timeZoneIdentifier: "Europe/London"),
        TimeZoneOption(label: "Dublin", timeZoneIdentifier: "Europe/Dublin"),
        TimeZoneOption(label: "Lisbon", timeZoneIdentifier: "Europe/Lisbon"),
        TimeZoneOption(label: "Paris", timeZoneIdentifier: "Europe/Paris"),
        TimeZoneOption(label: "Berlin", timeZoneIdentifier: "Europe/Berlin"),
        TimeZoneOption(label: "Warsaw", timeZoneIdentifier: "Europe/Warsaw"),
        TimeZoneOption(label: "Kyiv", timeZoneIdentifier: "Europe/Kyiv"),
        TimeZoneOption(label: "Istanbul", timeZoneIdentifier: "Europe/Istanbul"),
        TimeZoneOption(label: "Cairo", timeZoneIdentifier: "Africa/Cairo"),
        TimeZoneOption(label: "Johannesburg", timeZoneIdentifier: "Africa/Johannesburg"),
        TimeZoneOption(label: "Nairobi", timeZoneIdentifier: "Africa/Nairobi"),
        TimeZoneOption(label: "Dubai", timeZoneIdentifier: "Asia/Dubai"),
        TimeZoneOption(label: "New Delhi", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneOption(label: "Mumbai", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneOption(label: "Bengaluru", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneOption(label: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        TimeZoneOption(label: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong"),
        TimeZoneOption(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo"),
        TimeZoneOption(label: "Seoul", timeZoneIdentifier: "Asia/Seoul"),
        TimeZoneOption(label: "Sydney", timeZoneIdentifier: "Australia/Sydney"),
        TimeZoneOption(label: "Melbourne", timeZoneIdentifier: "Australia/Melbourne"),
        TimeZoneOption(label: "Auckland", timeZoneIdentifier: "Pacific/Auckland"),
        TimeZoneOption(label: "Honolulu", timeZoneIdentifier: "Pacific/Honolulu")
    ]

    static let all: [TimeZoneOption] = {
        var values = featured
        var keys = Set(values.map(\.id))

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            let option = TimeZoneOption(
                label: displayName(for: identifier),
                timeZoneIdentifier: identifier
            )
            if keys.insert(option.id).inserted {
                values.append(option)
            }
        }
        return values
    }()

    static func search(_ query: String, limit: Int = 60) -> [TimeZoneOption] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return Array(featured.prefix(limit)) }

        return all.lazy.filter { option in
            option.label.lowercased().contains(normalized)
                || option.timeZoneIdentifier.lowercased().contains(normalized)
        }
        .prefix(limit)
        .map { $0 }
    }

    static func displayName(for identifier: String) -> String {
        let finalComponent = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return finalComponent.replacingOccurrences(of: "_", with: " ")
    }
}
