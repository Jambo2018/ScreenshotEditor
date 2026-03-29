# ScreenshotEditor - Development Guide

## Testing

**Framework**: XCTest (built-in to Xcode)

**Run tests**: Press `⌘U` in Xcode or see `TESTING.md` for details.

**Test files**: `ScreenshotEditorTests/`

**Conventions**:
- 100% test coverage is the goal — tests make vibe coding safe
- When writing new functions, write a corresponding test
- When fixing a bug, write a regression test
- When adding error handling, write a test that triggers the error
- When adding a conditional (if/else, switch), write tests for BOTH paths
- Never commit code that makes existing tests fail

## Automated Development Flow (gstack multi-agent)

This project supports fully automated multi-role development using gstack skills.

### Available Roles

| Role | Command | Description |
|------|---------|-------------|
| **Product/CEO** | `/plan-ceo-review` | Scope, strategy, product decisions |
| **Design** | `/plan-design-review` | UI/UX review, visual consistency |
| **Engineering** | `/plan-eng-review` | Architecture, code quality, tests |
| **Auto-Review** | `/autoplan` | Run all 3 reviews in sequence |
| **QA** | `/qa` | Test → fix → verify loop |
| **Investigate** | `/investigate` | Root cause debugging |
| **Ship** | `/ship` | Full ship workflow |
| **Security** | `/cso` | OWASP security audit |
| **Docs** | `/document-release` | Auto-update documentation |

### Workflow: Complete Automation

**For new features:**
```
1. /office-hours          # Understand the problem space
2. /plan-ceo-review       # Define scope & strategy
3. /plan-design-review    # Design the UX
4. /plan-eng-review       # Plan architecture
5. [Implement feature]
6. /qa                    # Auto test + fix loop
7. /ship                  # Commit, PR, merge
8. /document-release      # Update docs
```

**For bug fixes:**
```
1. /investigate           # Root cause analysis
2. [Apply fix]
3. /qa                    # Verify + regression tests
4. /ship                  # Ship the fix
```

**For code review:**
```
1. /review                # Pre-landing review
2. /autoplan              # Full review gauntlet (optional)
3. /ship                  # Merge if all clear
```

### Pre-Ship Automation

Before every `/ship`, the following runs automatically:
1. **Test Suite** - All XCTest tests must pass
2. **Pre-Landing Review** - Code quality checklist
3. **Coverage Audit** - Ensure new code is tested
4. **Build Verification** - App compiles successfully

If any step fails, auto-fix is attempted. If fix fails, user is notified.

## Project Structure

```
ScreenshotEditor/
├── ScreenshotEditorApp.swift    # App entry point
├── Views/
│   ├── ContentView.swift        # Main layout
│   ├── ScreenshotListView.swift # Left sidebar
│   ├── CanvasView.swift         # Center canvas
│   ├── ControlPanelView.swift   # Right controls
│   ├── ErrorView.swift          # Error alerts
│   └── SettingsView.swift       # Settings window
├── Models/
│   ├── AppState.swift           # Main state manager
│   └── Screenshot.swift         # Screenshot model
├── Utilities/
│   └── ImageExporter.swift      # Image export logic
├── ScreenshotEditorTests/       # Unit + UI tests
└── Preview Content/             # Preview assets
```

## Build & Run

```bash
open ScreenshotEditor.xcodeproj
# Then press ⌘R to run
```

## Key Components

### AppState (`Models/AppState.swift`)

ObservableObject that manages all app state:
- `screenshots: [Screenshot]` - List of imported screenshots
- `backgroundType` - gradient, solid, blur, image
- `padding`, `cornerRadius`, `blurAmount` - export settings
- `showShadow`, `showBorder` - decoration toggles
- `exportCurrent()` - main export method

### ImageExporter (`Utilities/ImageExporter.swift`)

Pure functions for image processing:
- `exportImage()` - main export entry point
- Background creation (gradient, solid, blur)
- Corner radius, shadow application
- Format conversion (PNG, JPEG, WebP→PNG)

### Screenshot (`Models/Screenshot.swift`)

Model for screenshot data:
- `id`, `name`, `sourceURL`, `createdAt`, `image`
- `thumbnail` computed property

## Adding Features

1. Add the feature in the relevant component
2. Write tests for the new behavior
3. Run tests (`⌘U`) - all must pass
4. Commit with descriptive message

## Debugging

- Check Xcode console for `print()` output
- Use breakpoints in SwiftUI views
- For AppState issues, check the environment object binding
