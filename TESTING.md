# Testing Guide

## Test Framework

**Framework**: XCTest (built-in to Xcode)

**Test Targets**:
- `ScreenshotEditorTests` - Unit tests for models and utilities
- `ScreenshotEditorUITests` - UI tests for user flows

## Running Tests

### In Xcode (Recommended)

1. Open `ScreenshotEditor.xcodeproj`
2. Press `⌘U` to run all tests
3. Or use Product → Test from the menu
4. To run individual tests, click the diamond icon next to a test function

### From Command Line

```bash
cd ~/Desktop/ScreenshotEditor
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS'
```

## Test Coverage

### Unit Tests

| Component | Tests | Coverage |
|-----------|-------|----------|
| ImageExporter | 16 tests | Export paths, backgrounds, effects |
| AppState | 20 tests | State management, CRUD operations |

### UI Tests

| Feature | Tests |
|---------|-------|
| App Launch | ✓ |
| Menu Bar | ✓ |
| Import/Export Buttons | ✓ |
| Window Behavior | ✓ |

## Test Files

```
ScreenshotEditorTests/
├── ImageExporterTests.swift    # Unit tests for image export
├── AppStateTests.swift         # Unit tests for app state
├── ScreenshotEditorUITests.swift # UI tests
└── README.md                   # Test documentation
```

## Writing New Tests

### Unit Test Template

```swift
import XCTest
@testable import ScreenshotEditor

final class MyComponentTests: XCTestCase {

    func testSomething() throws {
        // Arrange
        let component = MyComponent()

        // Act
        let result = component.doSomething()

        // Assert
        XCTAssertEqual(result, expectedValue)
    }
}
```

### UI Test Template

```swift
import XCTest

final class MyFeatureUITests: XCTestCase {

    var app: XCApplication!

    override func setUp() async throws {
        app = XCUIApplication()
        app.launch()
    }

    func testUserFlow() throws {
        let button = app.buttons["My Button"]
        XCTAssertTrue(button.exists)
        button.tap()
    }
}
```

## Test Conventions

1. **Naming**: `test[Feature][Scenario]()`, e.g., `testExportWithCornerRadius()`
2. **Pattern**: Arrange-Act-Assert
3. **One assertion per test** (ideally)
4. **Use setUp/tearDown** for common setup
5. **Mock external dependencies**

## Test Expectations

When adding new features:

- **New functions**: Write a corresponding unit test
- **Bug fixes**: Write a regression test
- **Error handling**: Test that the error is thrown
- **Conditionals**: Test both paths (if/else, switch)
- **UI changes**: Add UI test for the flow

## Current Test Count

- **Unit Tests**: 36 tests
- **UI Tests**: 12 tests
- **Total**: 48 tests
