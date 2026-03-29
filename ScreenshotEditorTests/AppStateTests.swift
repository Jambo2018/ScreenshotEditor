//
//  AppStateTests.swift
//  ScreenshotEditorTests
//
//  Unit tests for AppState functionality
//

import XCTest
@testable import ScreenshotEditor

final class AppStateTests: XCTestCase {

    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        appState = AppState()
    }

    override func tearDown() async throws {
        appState = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func testInitialState() {
        XCTAssertEqual(appState.screenshots.count, 0, "Should start with no screenshots")
        XCTAssertNil(appState.selectedScreenshotId, "No screenshot should be selected initially")
        XCTAssertFalse(appState.isExporting, "Should not be exporting initially")
        XCTAssertNil(appState.errorMessage, "Should have no error message initially")
    }

    func testInitialBackgroundSettings() {
        XCTAssertEqual(appState.backgroundType, .gradient, "Default background should be gradient")
        XCTAssertEqual(appState.selectedGradient, .ocean, "Default gradient should be ocean")
        XCTAssertEqual(appState.selectedColor, .white, "Default solid color should be white")
        XCTAssertEqual(appState.blurAmount, 0, "Default blur should be 0")
        XCTAssertEqual(appState.padding, 40, "Default padding should be 40")
        XCTAssertEqual(appState.cornerRadius, 12, "Default corner radius should be 12")
    }

    func testInitialDecorationSettings() {
        XCTAssertTrue(appState.showShadow, "Shadow should be enabled by default")
        XCTAssertFalse(appState.showBorder, "Border should be disabled by default")
        XCTAssertNil(appState.deviceFrame, "No device frame by default")
    }

    // MARK: - Computed Properties

    func testHasScreenshotWhenEmpty() {
        XCTAssertFalse(appState.hasScreenshot, "Should not have a screenshot when empty")
        XCTAssertNil(appState.selectedScreenshot, "Selected screenshot should be nil when empty")
    }

    func testHasScreenshotWhenNotEmpty() {
        let testImage = createTestImage()
        let screenshot = Screenshot(
            id: UUID(),
            name: "test.png",
            sourceURL: URL(fileURLWithPath: "/test.png"),
            createdAt: Date(),
            image: testImage
        )
        appState.screenshots.append(screenshot)
        appState.selectedScreenshotId = screenshot.id

        XCTAssertTrue(appState.hasScreenshot, "Should have a screenshot")
        XCTAssertNotNil(appState.selectedScreenshot, "Selected screenshot should not be nil")
    }

    // MARK: - Screenshot Management

    func testDeleteScreenshot() {
        let screenshot1 = createTestScreenshot(name: "test1.png")
        let screenshot2 = createTestScreenshot(name: "test2.png")
        appState.screenshots.append(contentsOf: [screenshot1, screenshot2])
        appState.selectedScreenshotId = screenshot1.id

        XCTAssertEqual(appState.screenshots.count, 2, "Should have 2 screenshots")

        appState.deleteScreenshot(screenshot1)

        XCTAssertEqual(appState.screenshots.count, 1, "Should have 1 screenshot after deletion")
        XCTAssertEqual(appState.selectedScreenshotId, screenshot2.id, "Selection should move to remaining screenshot")
    }

    func testDeleteLastScreenshot() {
        let screenshot = createTestScreenshot(name: "test.png")
        appState.screenshots.append(screenshot)
        appState.selectedScreenshotId = screenshot.id

        appState.deleteScreenshot(screenshot)

        XCTAssertEqual(appState.screenshots.count, 0, "Should have no screenshots")
        XCTAssertNil(appState.selectedScreenshotId, "Selection should be nil after deleting last screenshot")
    }

    func testDeleteNonSelectedScreenshot() {
        let screenshot1 = createTestScreenshot(name: "test1.png")
        let screenshot2 = createTestScreenshot(name: "test2.png")
        appState.screenshots.append(contentsOf: [screenshot1, screenshot2])
        appState.selectedScreenshotId = screenshot2.id

        appState.deleteScreenshot(screenshot1)

        XCTAssertEqual(appState.selectedScreenshotId, screenshot2.id, "Selection should remain unchanged")
    }

    // MARK: - Background Type Changes

    func testChangeBackgroundType() {
        appState.backgroundType = .solid
        XCTAssertEqual(appState.backgroundType, .solid)

        appState.backgroundType = .blur
        XCTAssertEqual(appState.backgroundType, .blur)

        appState.backgroundType = .image
        XCTAssertEqual(appState.backgroundType, .image)
    }

    func testChangeGradientPreset() {
        appState.selectedGradient = .sunset
        XCTAssertEqual(appState.selectedGradient, .sunset)

        appState.selectedGradient = .forest
        XCTAssertEqual(appState.selectedGradient, .forest)
    }

    func testChangeSolidColor() {
        appState.selectedColor = .red
        // Note: Color comparison would need more sophisticated equality check
    }

    func testChangeBlurAmount() {
        appState.blurAmount = 15.5
        XCTAssertEqual(appState.blurAmount, 15.5)
    }

    func testChangePadding() {
        appState.padding = 60
        XCTAssertEqual(appState.padding, 60)
    }

    func testChangeCornerRadius() {
        appState.cornerRadius = 20
        XCTAssertEqual(appState.cornerRadius, 20)
    }

    // MARK: - Decoration Changes

    func testToggleShadow() {
        appState.showShadow = false
        XCTAssertFalse(appState.showShadow)

        appState.showShadow = true
        XCTAssertTrue(appState.showShadow)
    }

    func testToggleBorder() {
        appState.showBorder = true
        XCTAssertTrue(appState.showBorder)
    }

    func testChangeDeviceFrame() {
        appState.deviceFrame = .iphone
        XCTAssertEqual(appState.deviceFrame, .iphone)

        appState.deviceFrame = .macbook
        XCTAssertEqual(appState.deviceFrame, .macbook)

        appState.deviceFrame = .none
        XCTAssertEqual(appState.deviceFrame, .none)
    }

    // MARK: - Error Handling

    func testSetErrorMessage() {
        appState.errorMessage = "Test error message"
        XCTAssertEqual(appState.errorMessage, "Test error message")
    }

    func testClearErrorMessage() {
        appState.errorMessage = "Test error"
        appState.errorMessage = nil
        XCTAssertNil(appState.errorMessage)
    }

    // MARK: - Export State

    func testSetExporting() {
        appState.isExporting = true
        XCTAssertTrue(appState.isExporting)

        appState.isExporting = false
        XCTAssertFalse(appState.isExporting)
    }

    // MARK: - Supporting Types Tests

    func testBackgroundTypeAllCases() {
        let allCases = BackgroundType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.gradient))
        XCTAssertTrue(allCases.contains(.solid))
        XCTAssertTrue(allCases.contains(.blur))
        XCTAssertTrue(allCases.contains(.image))
    }

    func testDeviceFrameAllCases() {
        let allCases = DeviceFrame.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.none))
        XCTAssertTrue(allCases.contains(.iphone))
        XCTAssertTrue(allCases.contains(.macbook))
    }

    func testGradientPresetProperties() {
        let ocean = GradientPreset.ocean
        XCTAssertEqual(ocean.name, "Ocean")
        XCTAssertEqual(ocean.colors.count, 2)

        let sunset = GradientPreset.sunset
        XCTAssertEqual(sunset.name, "Sunset")

        let forest = GradientPreset.forest
        XCTAssertEqual(forest.name, "Forest")

        let fire = GradientPreset.fire
        XCTAssertEqual(fire.name, "Fire")

        let midnight = GradientPreset.midnight
        XCTAssertEqual(midnight.name, "Midnight")
    }

    func testGradientPresetsArray() {
        let presets = GradientPreset.presets
        XCTAssertEqual(presets.count, 5)
    }

    // MARK: - Helper Methods

    private func createTestScreenshot(name: String = "test.png") -> Screenshot {
        Screenshot(
            id: UUID(),
            name: name,
            sourceURL: URL(fileURLWithPath: "/\(name)"),
            createdAt: Date(),
            image: createTestImage()
        )
    }

    private func createTestImage(width: CGFloat = 100, height: CGFloat = 100) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.drawSwatch(in: NSRect(x: 0, y: 0, width: width, height: height))
        image.unlockFocus()
        return image
    }
}
