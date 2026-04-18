//
//  AppStateTests.swift
//  ScreenshotEditorTests
//

import XCTest
import SwiftUI
import AppKit
@testable import ScreenshotEditor

final class AppStateTests: XCTestCase {

    private var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        appState = AppState(testHarness: .unitTests)
    }

    override func tearDown() async throws {
        appState = nil
        try await super.tearDown()
    }

    func testInitialEditingDefaults() {
        XCTAssertEqual(appState.screenshots.count, 0)
        XCTAssertNil(appState.selectedScreenshotId)
        XCTAssertEqual(appState.backgroundType, .color)
        XCTAssertEqual(appState.selectedGradient, .cool)
        XCTAssertEqual(appState.padding, 40)
        XCTAssertEqual(appState.cornerRadius, 12)
        XCTAssertFalse(appState.showShadow)
        XCTAssertFalse(appState.showBorder)
        XCTAssertEqual(appState.deviceFrame, .none)
        XCTAssertEqual(appState.exportAspectRatio, .original)
    }

    func testHasScreenshotReflectsCurrentSelection() {
        XCTAssertFalse(appState.hasScreenshot)

        let screenshot = makeScreenshot(name: "first.png")
        appState.setCurrentScreenshot(screenshot)

        XCTAssertTrue(appState.hasScreenshot)
        XCTAssertEqual(appState.selectedScreenshot?.id, screenshot.id)
    }

    func testSetCurrentScreenshotReplacesPreviousImportAndClearsAnnotations() {
        let first = makeScreenshot(name: "first.png")
        let second = makeScreenshot(name: "second.png")

        appState.annotations = [makeAnnotation()]
        appState.selectedAnnotationId = appState.annotations.first?.id
        appState.setCurrentScreenshot(first)
        appState.annotations = [makeAnnotation()]
        appState.selectedAnnotationId = appState.annotations.first?.id

        appState.setCurrentScreenshot(second)

        XCTAssertEqual(appState.screenshots.count, 1)
        XCTAssertEqual(appState.selectedScreenshot?.id, second.id)
        XCTAssertEqual(appState.selectedScreenshotIds, [second.id])
        XCTAssertTrue(appState.annotations.isEmpty)
        XCTAssertNil(appState.selectedAnnotationId)
    }

    func testDeleteCurrentScreenshotClearsSelectionAndAnnotations() {
        let screenshot = makeScreenshot(name: "test.png")
        appState.setCurrentScreenshot(screenshot)
        appState.annotations = [makeAnnotation()]
        appState.selectedAnnotationId = appState.annotations.first?.id

        appState.deleteScreenshot(screenshot)

        XCTAssertFalse(appState.hasScreenshot)
        XCTAssertTrue(appState.screenshots.isEmpty)
        XCTAssertTrue(appState.annotations.isEmpty)
        XCTAssertNil(appState.selectedAnnotationId)
    }

    func testResolvedAspectRatioUsesCustomValues() {
        appState.exportAspectRatio = .custom
        appState.customAspectRatioWidth = 4
        appState.customAspectRatioHeight = 5

        XCTAssertEqual(appState.resolvedAspectRatioValue ?? 0, 4.0 / 5.0, accuracy: 0.0001)
    }

    func testUITestEditingScenarioSeedsScreenshotAndEditorState() {
        let uiState = AppState(testHarness: .uiTests(.editing))

        XCTAssertTrue(uiState.hasScreenshot)
        XCTAssertEqual(uiState.backgroundType, .color)
        XCTAssertEqual(uiState.selectedGradient, .violet)
        XCTAssertEqual(uiState.deviceFrame, .iphone)
        XCTAssertEqual(uiState.exportAspectRatio, .portrait34)
        XCTAssertEqual(uiState.padding, 36)
        XCTAssertEqual(uiState.cornerRadius, 18)
        XCTAssertEqual(uiState.blurAmount, 12)
        XCTAssertFalse(uiState.autoCopyToClipboard)
    }

    func testUITestImportRequestSeedsScreenshotWithoutShowingSystemImporter() {
        let uiState = AppState(testHarness: .uiTests(.empty))

        XCTAssertFalse(uiState.hasScreenshot)

        uiState.requestImageImport()

        XCTAssertTrue(uiState.hasScreenshot)
        XCTAssertEqual(uiState.selectedScreenshot?.name, "UITest-Import")
        XCTAssertFalse(uiState.isImportPickerPresented)
    }

    func testAutomationHarnessExportReturnsConfirmationMessage() {
        let uiState = AppState(testHarness: .uiTests(.editing))

        uiState.exportCurrent()

        XCTAssertEqual(uiState.errorMessage, "UITest export prepared")
        XCTAssertFalse(uiState.isExporting)
    }

    func testAutomationHarnessShareReturnsConfirmationMessage() {
        let uiState = AppState(testHarness: .uiTests(.editing))

        uiState.shareCurrent()

        XCTAssertEqual(uiState.errorMessage, "UITest share prepared")
    }

    func testEditorDeviceClassSizingRemainsDistinctAcrossPlatforms() {
        XCTAssertEqual(EditorDeviceClass.phone.topBarButtonSide, 28)
        XCTAssertEqual(EditorDeviceClass.tablet.topBarButtonSide, 30)
        XCTAssertEqual(EditorDeviceClass.desktop.topBarButtonSide, 32)

        XCTAssertLessThan(EditorDeviceClass.phone.bottomBarHorizontalPadding, EditorDeviceClass.desktop.bottomBarHorizontalPadding)
        XCTAssertNotNil(EditorDeviceClass.tablet.workspaceSectionWidth)
        XCTAssertEqual(EditorDeviceClass.desktop.workspaceSectionWidth, 332)
    }

    private func makeScreenshot(name: String) -> Screenshot {
        Screenshot(
            id: UUID(),
            name: name,
            sourceURL: URL(fileURLWithPath: "/tmp/\(name)"),
            createdAt: Date(),
            image: makeImage()
        )
    }

    private func makeImage(width: CGFloat = 120, height: CGFloat = 80) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
        image.unlockFocus()
        return image
    }

    private func makeAnnotation() -> Annotation {
        Annotation(
            id: UUID(),
            type: .text,
            text: "Test",
            position: CGPoint(x: 0.5, y: 0.5),
            fontSize: 16,
            color: CodableColor(color: .white),
            width: 0,
            startPoint: nil,
            endPoint: nil,
            size: nil,
            points: nil
        )
    }
}
