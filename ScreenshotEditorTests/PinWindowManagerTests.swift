//
//  PinWindowManagerTests.swift
//  ScreenshotEditorTests
//
//  Unit tests for PinWindowManager functionality
//

import XCTest
@testable import ScreenshotEditor

@MainActor
final class PinWindowManagerTests: XCTestCase {

    var manager: PinWindowManager!
    var testImage: NSImage!

    override func setUp() async throws {
        try await super.setUp()
        manager = PinWindowManager.shared
        testImage = createTestImage()
        manager.resetForTesting()
    }

    override func tearDown() async throws {
        manager.resetForTesting()
        manager = nil
        testImage = nil
        try await super.tearDown()
    }

    private func waitForActivePins(count expectedCount: Int, timeout: TimeInterval = 1.0, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while manager.activePins.count != expectedCount && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertEqual(manager.activePins.count, expectedCount, file: file, line: line)
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = PinWindowManager.shared
        let instance2 = PinWindowManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same singleton instance")
    }

    // MARK: - Pin Creation Tests

    func testCreatePin() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Should return a pin ID")
            return
        }

        XCTAssertEqual(manager.activePins.count, 1, "Should have 1 active pin")
        XCTAssertNotNil(manager.activePins[pinId], "Pin should exist in active pins")
    }

    func testCreatePinWithPosition() {
        let position = CGPoint(x: 100, y: 200)
        guard let pinId = manager.createPin(image: testImage, position: position) else {
            XCTFail("Pin should exist")
            return
        }

        guard let pin = manager.activePins[pinId] else {
            XCTFail("Pin should exist")
            return
        }

        XCTAssertEqual(pin.frame.origin.x, position.x, accuracy: 10)
        XCTAssertEqual(pin.frame.origin.y, position.y, accuracy: 10)
    }

    func testCreatePinWithGroup() {
        let groupName = "TestGroup"
        guard let pinId = manager.createPin(image: testImage, position: nil, group: groupName) else {
            XCTFail("Pin should exist")
            return
        }

        let pinsInGroup = manager.pinsInGroup(groupName)
        XCTAssertTrue(pinsInGroup.contains(pinId), "Pin should be in the group")
    }

    func testCreateMultiplePins() {
        guard
            let pin1 = manager.createPin(image: testImage),
            let pin2 = manager.createPin(image: testImage),
            let pin3 = manager.createPin(image: testImage)
        else {
            XCTFail("Pins should exist")
            return
        }

        XCTAssertEqual(manager.activePins.count, 3, "Should have 3 active pins")
        XCTAssertNotNil(manager.activePins[pin1])
        XCTAssertNotNil(manager.activePins[pin2])
        XCTAssertNotNil(manager.activePins[pin3])
    }

    // MARK: - Pin Closure Tests

    func testClosePin() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        XCTAssertEqual(manager.activePins.count, 1)

        manager.closePin(id: pinId)
        waitForActivePins(count: 0)

        XCTAssertEqual(manager.activePins.count, 0, "Pin should be removed")
        XCTAssertNil(manager.activePins[pinId], "Pin should not exist after closing")
    }

    func testCloseNonExistentPin() {
        let fakeId = UUID()
        manager.closePin(id: fakeId)
        // Should not crash
    }

    func testCloseAllPins() {
        _ = manager.createPin(image: testImage)
        _ = manager.createPin(image: testImage)
        _ = manager.createPin(image: testImage)

        XCTAssertEqual(manager.activePins.count, 3)

        manager.resetForTesting()

        XCTAssertEqual(manager.activePins.count, 0, "All pins should be closed")
    }

    func testCloseOtherPins() {
        guard
            let pin1 = manager.createPin(image: testImage),
            let pin2 = manager.createPin(image: testImage),
            let pin3 = manager.createPin(image: testImage)
        else {
            XCTFail("Pins should exist")
            return
        }

        manager.closeOtherPins(except: pin2)
        waitForActivePins(count: 1)

        XCTAssertEqual(manager.activePins.count, 1, "Only one pin should remain")
        XCTAssertNotNil(manager.activePins[pin2], " pin2 should remain")
        XCTAssertNil(manager.activePins[pin1], "pin1 should be closed")
        XCTAssertNil(manager.activePins[pin3], "pin3 should be closed")
    }

    // MARK: - Group Management Tests

    func testAddToGroup() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        let groupName = "TestGroup"

        manager.addToGroup(groupName, pinId: pinId)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertTrue(pins.contains(pinId), "Pin should be in group")
    }

    func testRemoveFromGroup() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        let groupName = "TestGroup"

        manager.addToGroup(groupName, pinId: pinId)
        manager.removeFromGroup(groupName, pinId: pinId)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertFalse(pins.contains(pinId), "Pin should be removed from group")
    }

    func testMultiplePinsInGroup() {
        guard
            let pin1 = manager.createPin(image: testImage),
            let pin2 = manager.createPin(image: testImage),
            let pin3 = manager.createPin(image: testImage)
        else {
            XCTFail("Pins should exist")
            return
        }

        let groupName = "MultiPinGroup"
        manager.addToGroup(groupName, pinId: pin1)
        manager.addToGroup(groupName, pinId: pin2)
        manager.addToGroup(groupName, pinId: pin3)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertEqual(pins.count, 3, "Should have 3 pins in group")
    }

    func testHideAndShowGroup() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        let groupName = "VisibilityGroup"

        manager.addToGroup(groupName, pinId: pinId)

        manager.hideGroup(groupName)

        guard let pin = manager.activePins[pinId] else {
            XCTFail("Pin should exist")
            return
        }
        XCTAssertEqual(pin.alphaValue, 0.0, "Pin should be hidden")

        manager.showGroup(groupName)
        XCTAssertEqual(pin.alphaValue, 1.0, "Pin should be visible")
    }

    func testToggleGroup() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        let groupName = "ToggleGroup"

        manager.addToGroup(groupName, pinId: pinId)

        // Initially visible
        manager.toggleGroup(groupName)
        guard let pin = manager.activePins[pinId] else {
            XCTFail("Pin should exist")
            return
        }
        XCTAssertEqual(pin.alphaValue, 0.0, "Pin should be hidden after first toggle")

        manager.toggleGroup(groupName)
        XCTAssertEqual(pin.alphaValue, 1.0, "Pin should be visible after second toggle")
    }

    func testGroupCleanupAfterPinClose() {
        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        let groupName = "CleanupGroup"

        manager.addToGroup(groupName, pinId: pinId)

        manager.closePin(id: pinId)
        waitForActivePins(count: 0)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertTrue(pins.isEmpty, "Group should be empty after pin is closed")
    }

    // MARK: - Statistics Tests

    func testActivePinCount() {
        XCTAssertEqual(manager.activePinCount, 0, "Should start with 0 pins")

        _ = manager.createPin(image: testImage)
        XCTAssertEqual(manager.activePinCount, 1)

        _ = manager.createPin(image: testImage)
        XCTAssertEqual(manager.activePinCount, 2)

        manager.closeAllPins()
        waitForActivePins(count: 0)
        XCTAssertEqual(manager.activePinCount, 0)
    }

    func testGroupCount() {
        XCTAssertEqual(manager.groupCount, 0, "Should start with 0 groups")

        guard let pinId = manager.createPin(image: testImage) else {
            XCTFail("Pin should exist")
            return
        }
        manager.addToGroup("Group1", pinId: pinId)
        XCTAssertEqual(manager.groupCount, 1)

        manager.addToGroup("Group2", pinId: pinId)
        XCTAssertEqual(manager.groupCount, 2)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: CGFloat = 400, height: CGFloat = 300) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.drawSwatch(in: NSRect(x: 0, y: 0, width: width, height: height))
        image.unlockFocus()
        return image
    }
}
