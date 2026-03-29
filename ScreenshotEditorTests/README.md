# ScreenshotEditorTests

Unit tests and UI tests for the ScreenshotEditor macOS app.

## Test Targets

### ScreenshotEditorTests (Unit Tests)

Unit tests for the core business logic:

- **ImageExporterTests**: Tests for image export functionality
  - Basic export (PNG, JPEG, WebP fallback)
  - Background types (gradient, solid, blur)
  - Corner radius application
  - Shadow effects
  - Padding handling
  - All gradient presets

- **AppStateTests**: Tests for app state management
  - Initial state verification
  - Screenshot CRUD operations
  - Background setting changes
  - Decoration toggles
  - Error handling
  - Computed properties

### ScreenshotEditorUITests (UI Tests)

UI tests for user interaction flows:

- App launch verification
- Menu bar existence
- Import/export button presence
- Navigation structure
- Window behavior
- Keyboard shortcuts
- Performance (launch time)

## Running Tests

### In Xcode

1. Open `ScreenshotEditor.xcodeproj`
2. Press `⌘U` to run all tests
3. Or use Product → Test from the menu

### From Command Line

```bash
cd ~/Desktop/ScreenshotEditor
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS'
```

## Test Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| ImageExporter | 90%+ (all export paths, error cases) |
| AppState | 80%+ (state changes, computed properties) |
| Views | UI tests for main flows |

## Adding New Tests

1. Create test file in `ScreenshotEditorTests/`
2. Name format: `{Component}Tests.swift`
3. Inherit from `XCTestCase`
4. Use `@testable import ScreenshotEditor` for unit tests

## Test Conventions

- Use descriptive test names: `test[Feature][Scenario]()`
- Arrange-Act-Assert pattern
- One assertion per test (ideally)
- Use `setUp()` and `tearDown()` for common setup
- Mock external dependencies

## CI/CD Integration

Add to your GitHub Actions or other CI:

```yaml
- name: Run Tests
  run: xcodebuild test -project ScreenshotEditor.xcodeproj -scheme ScreenshotEditor -destination 'platform=macOS'
```
