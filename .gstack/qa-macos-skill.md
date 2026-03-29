---
name: qa-macos
version: 1.0.0
description: |
  macOS App QA — Test → Fix → Verify loop for Swift/Xcode projects.
  Automatically runs XCTest suite, analyzes failures, applies fixes, and re-tests.
  Use when asked to "test the app", "run QA", "fix test failures", or "verify builds".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /qa-macos: Automated QA for macOS Apps

## Workflow

### Phase 1: Pre-flight

1. **Check working tree:**
   ```bash
   git status --porcelain
   ```
   If dirty, offer to commit current changes first.

2. **Check test configuration:**
   ```bash
   xcodebuild -list -project ScreenshotEditor.xcodeproj
   ```
   Verify the scheme has test action configured.

3. **Create output directory:**
   ```bash
   mkdir -p .gstack/qa-reports/screenshots
   ```

### Phase 2: Run Tests

```bash
.gstack/bin/qa-test-runner.sh
```

Parse the output:
- If **PASS**: Report success, skip to Phase 6
- If **FAIL**: Extract failure details, continue to Phase 3

### Phase 3: Analyze Failures

For each test failure:

1. **Identify the failing test:**
   - Test class name (e.g., `ImageExporterTests.testBasicPNGExport`)
   - Error message
   - File/line if available

2. **Classify the failure:**
   - **Assertion failure** — Logic bug in test or code
   - **Compilation error** — Import/syntax issue
   - **Runtime crash** — Nil unwrap, out of bounds
   - **Timeout** — Async code not completing
   - **Configuration** — Scheme/destination issue

3. **Locate source files:**
   ```bash
   # Find the test file
   find . -name "*Tests.swift" | xargs grep -l "testName"

   # Find the source file being tested
   grep -r "func testedFunction" --include="*.swift" | grep -v Tests
   ```

### Phase 4: Apply Fix

For each failure:

1. **Read the failing code** — understand context
2. **Apply minimal fix** — smallest change that resolves the issue
3. **Commit the fix:**
   ```bash
   git add <files>
   git commit -m "fix(qa): <test-name> — <brief description>"
   ```

### Phase 5: Re-test

Re-run the test suite:
```bash
.gstack/bin/qa-test-runner.sh
```

- If **PASS**: Continue to Phase 6
- If **FAIL**: Return to Phase 3 (max 3 iterations)

### Phase 6: Generate Report

Write to `.gstack/qa-reports/qa-report-YYYY-MM-DD.md`:

```markdown
# QA Report — {date}

## Summary
- **Status**: PASS / FAIL
- **Tests**: N total, M passed, K failed
- **Fixes Applied**: X

## Test Results
| Test Class | Passed | Failed |
|------------|--------|--------|
| ImageExporterTests | 10 | 0 |
| AppStateTests | 8 | 1 |

## Fixes Applied
1. `ImageExporterTests.testPNGExport` — Fixed nil image handling (commit: abc123)

## Health Score
{0-100 based on pass rate}
```

### Phase 7: Regression Tests

For each fix applied, add a regression test:

1. **Find existing test conventions:**
   ```bash
   head -50 ScreenshotEditorTests/ImageExporterTests.swift
   ```

2. **Add new test case:**
   ```swift
   // Regression: {issue} found by /qa on {date}
   func testEdgeCaseThatFailed() throws {
       // Arrange
       // Act
       // Assert
   }
   ```

3. **Verify new test passes**

### Phase 8: Finalize

1. **Update CLAUDE.md** if testing conventions changed
2. **Update TESTING.md** with any new test patterns
3. **Commit regression tests:**
   ```bash
   git commit -m "test(qa): regression test for {issue}"
   ```

## Test Framework Helpers

### Run specific test class
```bash
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS' \
  -only-testing:ScreenshotEditorTests/ImageExporterTests
```

### Run specific test method
```bash
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS' \
  -only-testing:ScreenshotEditorTests/ImageExporterTests/testBasicPNGExport
```

### Get test coverage
```bash
xcodebuild test \
  -project ScreenshotEditor.xcodeproj \
  -scheme ScreenshotEditor \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

## Ship Integration

When `/ship` runs, it automatically invokes this `/qa-macos` flow before:
- Version bump
- CHANGELOG update
- Push

If QA fails after 3 fix iterations, `/ship` halts and reports to user.
