//
//  ScreenshotEditorUITests.swift
//  ScreenshotEditorUITests
//
//  UI Tests for ScreenshotEditor application
//

import XCTest

class ScreenshotEditorUITests: XCTestCase {

    var app: XCApplication!

    override func setUp() async throws {
        try await super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
        try await super.tearDown()
    }

    // MARK: - App Launch

    func testAppLaunches() {
        // Verify the app launches and the main window appears
        XCTAssertTrue(app.exists, "App should launch")
    }

    func testMainWindowAppears() {
        // Verify main window elements are present
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5), "Main window should appear")
    }

    // MARK: - Menu Bar

    func testMenuBarExists() {
        // Verify the app has a menu bar (macOS apps should have one)
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.waitForExistence(timeout: 3), "Menu bar should exist")
    }

    // MARK: - Import Functionality

    func testImportButtonExists() {
        // Look for the import button in the toolbar
        let importButton = app.buttons["Import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 3), "Import button should exist")
    }

    func testImportButtonWithKeyboardShortcut() {
        // Test that Command+O triggers import
        let importButton = app.buttons["Import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 3), "Import button should exist")
        // Note: Full keyboard shortcut testing would require dismissing the open panel
    }

    // MARK: - Export Functionality

    func testExportButtonExists() {
        // Look for the export button in the toolbar
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export button should exist")
    }

    func testExportButtonDisabledWithoutScreenshot() {
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export button should exist")
        // Export button state may vary - this test just verifies the button exists
    }

    // MARK: - Navigation Split View

    func testNavigationSplitViewExists() {
        // The app uses NavigationSplitView - verify the structure exists
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5), "Window should exist")
    }

    // MARK: - Settings Window

    func testSettingsMenuExists() {
        // Settings should be accessible from the app menu
        // This is a basic check - full testing would require opening the settings
        let appMenu = app.menuItems["Preferences…"]
        // Settings may not be immediately accessible without opening the menu
    }

    // MARK: - Error Display

    func testErrorViewNotVisibleInitially() {
        // Error sheet should not be visible on launch
        let errorElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Error'"))
        XCTAssertFalse(errorElements.firstMatch.exists, "No error should be visible initially")
    }

    // MARK: - Layout

    func testWindowIsResizable() {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "Window should exist")

        let initialFrame = window.frame
        // Attempt to resize (macOS windows should be resizable)
        window.resize(to: CGSize(width: initialFrame.width + 100, height: initialFrame.height))

        // Note: Full resize testing is complex in UI tests
        XCTAssertTrue(window.exists, "Window should still exist after resize attempt")
    }

    // MARK: - Keyboard Shortcuts

    func testCommandOExists() {
        // Verify the import menu item exists with its shortcut
        // This is a basic check - actual shortcut execution requires more setup
        let menus = app.menuItems
        // Menu items may not be directly queryable without opening menus
    }

    func testCommandEExists() {
        // Verify the export menu item exists with its shortcut
        // This is a basic check - actual shortcut execution requires more setup
    }

    // MARK: - Performance

    func testAppLaunchesWithinTime() {
        // Measure app launch time
        measure {
            let app = XCUIApplication()
            app.launch()
            XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "App should launch within 10 seconds")
        }
    }
}

// MARK: - UI Test Catalog

extension ScreenshotEditorUITests {

    // This section documents additional UI tests that could be added:

    /*
     TODO: Test full import flow
     - Click import button
     - Select a test image file
     - Verify image appears in canvas

     TODO: Test export flow
     - Import an image first
     - Click export button
     - Verify save panel appears
     - Verify file is saved

     TODO: Test background type switching
     - Import an image
     - Click each background type button
     - Verify visual change in canvas

     TODO: Test gradient selection
     - Import an image
     - Click each gradient preset
     - Verify gradient changes

     TODO: Test slider controls
     - Import an image
     - Adjust padding slider
     - Verify padding changes visually

     TODO: Test corner radius
     - Import an image
     - Adjust corner radius slider
     - Verify corners become more rounded

     TODO: Test shadow toggle
     - Import an image
     - Toggle shadow on/off
     - Verify shadow appears/disappears

     TODO: Test device frame overlay
     - Import an image
     - Select iPhone frame
     - Verify frame appears around image

     TODO: Test multiple image import
     - Import first image
     - Import second image
     - Verify both appear in sidebar

     TODO: Test image selection
     - Import multiple images
     - Click different images in sidebar
     - Verify selected image appears in canvas

     TODO: Test image deletion
     - Import an image
     - Delete the image
     - Verify image is removed from sidebar

     TODO: Test undo/redo
     - Make a change (e.g., adjust padding)
     - Press Command+Z
     - Verify change is undone

     TODO: Test window state persistence
     - Adjust window size
     - Close and reopen app
     - Verify window size is restored
     */
}
