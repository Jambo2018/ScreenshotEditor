//
//  ScreenshotEditorUITests.swift
//  ScreenshotEditorTests
//

import XCTest
@testable import ScreenshotEditor

final class ScreenshotEditorUITests: XCTestCase {

    func testEmptyScenarioStartsWithoutScreenshot() {
        let appState = AppState(testHarness: .uiTests(.empty))

        XCTAssertFalse(appState.hasScreenshot)
        XCTAssertNil(appState.selectedScreenshot)
        XCTAssertEqual(appState.screenshots.count, 0)
    }

    func testImportActionTransitionsFromEmptyStateToEditing() {
        let appState = AppState(testHarness: .uiTests(.empty))

        appState.requestImageImport()

        XCTAssertTrue(appState.hasScreenshot)
        XCTAssertEqual(appState.screenshots.count, 1)
        XCTAssertEqual(appState.selectedScreenshot?.name, "UITest-Import")
        XCTAssertFalse(appState.isImportPickerPresented)
    }

    func testEditingScenarioCanExerciseExportAndShareAutomation() {
        let appState = AppState(testHarness: .uiTests(.editing))

        appState.exportCurrent()
        XCTAssertEqual(appState.errorMessage, "UITest export prepared")

        appState.shareCurrent()
        XCTAssertEqual(appState.errorMessage, "UITest share prepared")
    }

    func testEditingScenarioShowsAnnotationToolbarRegressionCoverage() {
        let appState = AppState(testHarness: .uiTests(.editing))

        XCTAssertTrue(appState.hasScreenshot)
        XCTAssertEqual(appState.deviceFrame, .iphone)
        XCTAssertEqual(appState.exportAspectRatio, .portrait34)
        XCTAssertEqual(appState.selectedAnnotationTool, .select)
        XCTAssertTrue(appState.selectedScreenshotIds.contains(appState.selectedScreenshotId!))
    }
}
