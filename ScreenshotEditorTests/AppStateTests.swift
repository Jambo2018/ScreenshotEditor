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
        appState = AppState()
    }

    override func tearDown() async throws {
        appState = nil
        try await super.tearDown()
    }

    func testInitialEditingDefaults() {
        XCTAssertEqual(appState.screenshots.count, 0)
        XCTAssertNil(appState.selectedScreenshotId)
        XCTAssertEqual(appState.backgroundType, .color)
        XCTAssertEqual(appState.selectedGradient, .cobalt)
        XCTAssertEqual(appState.padding, 40)
        XCTAssertEqual(appState.cornerRadius, 12)
        XCTAssertTrue(appState.showShadow)
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

        XCTAssertEqual(appState.resolvedAspectRatioValue, 4.0 / 5.0, accuracy: 0.0001)
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
