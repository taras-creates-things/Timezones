import Foundation
import XCTest
@testable import Timezones

final class TimeEngineTests: XCTestCase {
    func testOneInstantDisplaysCorrectlyAcrossZones() throws {
        let instant = try date("2026-01-15T12:00:00Z")

        XCTAssertEqual(
            TimeEngine.timeString(for: instant, in: try zone("America/Los_Angeles"), uses24HourTime: true),
            "04:00"
        )
        XCTAssertEqual(
            TimeEngine.timeString(for: instant, in: try zone("America/New_York"), uses24HourTime: true),
            "07:00"
        )
        XCTAssertEqual(
            TimeEngine.timeString(for: instant, in: try zone("Asia/Kolkata"), uses24HourTime: true),
            "17:30"
        )
    }

    func testDaylightSavingOffsetChangesForLosAngeles() throws {
        let losAngeles = try zone("America/Los_Angeles")
        let beforeTransition = try date("2024-03-10T09:30:00Z")
        let afterTransition = try date("2024-03-10T10:30:00Z")

        XCTAssertEqual(losAngeles.secondsFromGMT(for: beforeTransition), -8 * 60 * 60)
        XCTAssertEqual(losAngeles.secondsFromGMT(for: afterTransition), -7 * 60 * 60)
    }

    func testFractionalRelativeOffsetsArePreserved() throws {
        let instant = try date("2026-01-15T12:00:00Z")
        let warsaw = try zone("Europe/Warsaw")
        let delhi = try zone("Asia/Kolkata")

        XCTAssertEqual(
            TimeEngine.relativeOffsetString(for: instant, zone: delhi, relativeTo: warsaw),
            "+4H 30M"
        )
        XCTAssertEqual(TimeEngine.utcOffsetString(for: instant, in: delhi), "UTC+05:30")
    }

    func testDateLineContextUsesHomeCalendarDay() throws {
        let instant = try date("2026-08-03T23:30:00Z")
        let warsaw = try zone("Europe/Warsaw")
        let losAngeles = try zone("America/Los_Angeles")

        XCTAssertEqual(
            TimeEngine.relativeDayLabel(for: instant, zone: losAngeles, relativeTo: warsaw),
            "YESTERDAY"
        )
    }

    func testTimelineOffsetFormatting() {
        XCTAssertEqual(TimeEngine.timelineOffsetString(0), "NOW")
        XCTAssertEqual(TimeEngine.timelineOffsetString(2.5 * 60 * 60), "+2H 30M")
        XCTAssertEqual(TimeEngine.timelineOffsetString(-25 * 60 * 60), "−1D 1H")
    }

    func testPreferredAbbreviationsRemainCompact() throws {
        let summer = try date("2026-08-03T12:00:00Z")
        XCTAssertEqual(TimeEngine.abbreviation(for: summer, in: try zone("America/Los_Angeles")), "PDT")
        XCTAssertEqual(TimeEngine.abbreviation(for: summer, in: try zone("Asia/Kolkata")), "IST")
    }

    private func date(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: value))
    }

    private func zone(_ identifier: String) throws -> TimeZone {
        try XCTUnwrap(TimeZone(identifier: identifier))
    }
}
