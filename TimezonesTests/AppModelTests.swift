import Foundation
import XCTest
@testable import Timezones

@MainActor
final class AppModelTests: XCTestCase {
    func testTimelineSnapsToQuarterHoursAndClamps() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)

        model.setTimelineOffset(23 * 60)
        model.finishTimelineInteraction()
        XCTAssertEqual(model.timelineOffset, 30 * 60)

        model.setTimelineOffset(AppModel.maximumTimelineOffset * 2)
        XCTAssertEqual(model.timelineOffset, AppModel.maximumTimelineOffset)
    }

    func testAnimatedTimelineResetTravelsToNow() async {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)

        model.setTimelineOffset(2 * 60 * 60)
        model.animateTimelineToNow(duration: 0.08)

        try? await Task.sleep(nanoseconds: 35_000_000)
        XCTAssertGreaterThan(model.timelineOffset, 0)
        XCTAssertLessThan(model.timelineOffset, 2 * 60 * 60)

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(model.timelineOffset, 0, accuracy: 0.01)
    }

    func testTrackedZonesPersist() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)
        let option = TimeZoneOption(label: "Tokyo", timeZoneIdentifier: "Asia/Tokyo")
        model.addZone(option)

        let restored = AppModel(defaults: defaults)
        XCTAssertEqual(restored.zones.last?.label, "Tokyo")
        XCTAssertEqual(restored.zones.last?.timeZoneIdentifier, "Asia/Tokyo")
    }

    func testEditingAndDragReorderingPersist() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)
        let firstID = model.zones[0].id
        let lastID = model.zones[2].id

        var edited = model.zones[0]
        edited.label = "West Coast Client"
        edited.workSchedule.endMinute = 18 * 60
        model.updateZone(edited)
        model.moveZone(id: lastID, before: firstID)

        let restored = AppModel(defaults: defaults)
        XCTAssertEqual(restored.zones[0].id, lastID)
        XCTAssertEqual(restored.zones[1].label, "West Coast Client")
        XCTAssertEqual(restored.zones[1].workSchedule.endMinute, 18 * 60)
    }

    func testMovingZoneToIndexPersists() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)
        let firstID = model.zones[0].id

        model.moveZone(id: firstID, toIndex: 2)

        XCTAssertEqual(model.zones[2].id, firstID)
        XCTAssertEqual(AppModel(defaults: defaults).zones[2].id, firstID)
    }

    func testPanelDestinationsStayMutuallyExclusive() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(defaults: defaults)

        model.showSettings()
        XCTAssertTrue(model.isShowingSettings)
        XCTAssertFalse(model.isAddingZone)
        XCTAssertNil(model.editingZoneID)

        model.showAddZone()
        XCTAssertTrue(model.isAddingZone)
        XCTAssertFalse(model.isShowingSettings)
        XCTAssertNil(model.editingZoneID)

        model.beginEditingZone(id: model.zones[0].id)
        XCTAssertFalse(model.isAddingZone)
        XCTAssertFalse(model.isShowingSettings)
        XCTAssertEqual(model.editingZoneID, model.zones[0].id)

        model.showMainPanel()
        XCTAssertFalse(model.isAddingZone)
        XCTAssertFalse(model.isShowingSettings)
        XCTAssertNil(model.editingZoneID)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "TimezonesTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }
}
