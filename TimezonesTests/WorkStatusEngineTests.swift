import Foundation
import XCTest
@testable import Timezones

final class WorkStatusEngineTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!

    func testWorkdayPhases() throws {
        XCTAssertEqual(WorkStatusEngine.status(for: try date("2026-08-03T06:00:00Z"), in: utc, schedule: .standard), .beforeWork)
        XCTAssertEqual(WorkStatusEngine.status(for: try date("2026-08-03T10:00:00Z"), in: utc, schedule: .standard), .working)
        XCTAssertEqual(WorkStatusEngine.status(for: try date("2026-08-03T16:30:00Z"), in: utc, schedule: .standard), .wrappingUp)
        XCTAssertEqual(WorkStatusEngine.status(for: try date("2026-08-03T22:00:00Z"), in: utc, schedule: .standard), .night)
    }

    func testWeekendIsEvaluatedInTheTrackedTimezone() throws {
        XCTAssertEqual(
            WorkStatusEngine.status(for: try date("2026-08-02T12:00:00Z"), in: utc, schedule: .standard),
            .weekend
        )
    }

    private func date(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: value))
    }
}
