//
//  PinWindowManagerTests.swift
//  ScreenshotEditorTests
//
//  Unit tests for PinWindowManager functionality
//

import XCTest
@testable import ScreenshotEditor

final class PinWindowManagerTests: XCTestCase {

    var manager: PinWindowManager!
    var testImage: NSImage!

    override func setUp() async throws {
        try await super.setUp()
        manager = PinWindowManager.shared
        testImage = createTestImage()
        // Clean up any existing pins
        manager.closeAllPins()
    }

    override func tearDown() async throws {
        manager.closeAllPins()
        manager = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = PinWindowManager.shared
        let instance2 = PinWindowManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same singleton instance")
    }

    // MARK: - Pin Creation Tests

    func testCreatePin() {
        let pinId = manager.createPin(image: testImage)

        XCTAssertNotNil(pinId, "Should return a pin ID")
        XCTAssertEqual(manager.activePins.count, 1, "Should have 1 active pin")
        XCTAssertNotNil(manager.activePins[pinId], "Pin should exist in active pins")
    }

    func testCreatePinWithPosition() {
        let position = CGPoint(x: 100, y: 200)
        let pinId = manager.createPin(image: testImage, position: position)

        XCTAssertNotNil(pinId)
        guard let pin = manager.activePins[pinId] else {
            XCTFail("Pin should exist")
            return
        }

        XCTAssertEqual(pin.frame.origin.x, position.x, accuracy: 10)
        XCTAssertEqual(pin.frame.origin.y, position.y, accuracy: 10)
    }

    func testCreatePinWithGroup() {
        let groupName = "TestGroup"
        let pinId = manager.createPin(image: testImage, position: nil, group: groupName)

        XCTAssertNotNil(pinId)
        let pinsInGroup = manager.pinsInGroup(groupName)
        XCTAssertTrue(pinsInGroup.contains(pinId), "Pin should be in the group")
    }

    func testCreateMultiplePins() {
        let pin1 = manager.createPin(image: testImage)
        let pin2 = manager.createPin(image: testImage)
        let pin3 = manager.createPin(image: testImage)

        XCTAssertEqual(manager.activePins.count, 3, "Should have 3 active pins")
        XCTAssertNotNil(manager.activePins[pin1])
        XCTAssertNotNil(manager.activePins[pin2])
        XCTAssertNotNil(manager.activePins[pin3])
    }

    // MARK: - Pin Closure Tests

    func testClosePin() {
        let pinId = manager.createPin(image: testImage)
        XCTAssertEqual(manager.activePins.count, 1)

        manager.closePin(id: pinId)

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

        manager.closeAllPins()

        XCTAssertEqual(manager.activePins.count, 0, "All pins should be closed")
    }

    func testCloseOtherPins() {
        let pin1 = manager.createPin(image: testImage)
        let pin2 = manager.createPin(image: testImage)
        let pin3 = manager.createPin(image: testImage)

        manager.closeOtherPins(except: pin2)

        XCTAssertEqual(manager.activePins.count, 1, "Only one pin should remain")
        XCTAssertNotNil(manager.activePins[pin2], " pin2 should remain")
        XCTAssertNil(manager.activePins[pin1], "pin1 should be closed")
        XCTAssertNil(manager.activePins[pin3], "pin3 should be closed")
    }

    // MARK: - Group Management Tests

    func testAddToGroup() {
        let pinId = manager.createPin(image: testImage)
        let groupName = "TestGroup"

        manager.addToGroup(groupName, pinId: pinId)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertTrue(pins.contains(pinId), "Pin should be in group")
    }

    func testRemoveFromGroup() {
        let pinId = manager.createPin(image: testImage)
        let groupName = "TestGroup"

        manager.addToGroup(groupName, pinId: pinId)
        manager.removeFromGroup(groupName, pinId: pinId)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertFalse(pins.contains(pinId), "Pin should be removed from group")
    }

    func testMultiplePinsInGroup() {
        let pin1 = manager.createPin(image: testImage)
        let pin2 = manager.createPin(image: testImage)
        let pin3 = manager.createPin(image: testImage)

        let groupName = "MultiPinGroup"
        manager.addToGroup(groupName, pinId: pin1)
        manager.addToGroup(groupName, pinId: pin2)
        manager.addToGroup(groupName, pinId: pin3)

        let pins = manager.pinsInGroup(groupName)
        XCTAssertEqual(pins.count, 3, "Should have 3 pins in group")
    }

    func testHideAndShowGroup() {
        let pinId = manager.createPin(image: testImage)
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
        let pinId = manager.createPin(image: testImage)
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
        let pinId = manager.createPin(image: testImage)
        let groupName = "CleanupGroup"

        manager.addToGroup(groupName, pinId: pinId)

        manager.closePin(id: pinId)

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
        XCTAssertEqual(manager.activePinCount, 0)
    }

    func testGroupCount() {
        XCTAssertEqual(manager.groupCount, 0, "Should start with 0 groups")

        let pinId = manager.createPin(image: testImage)
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
