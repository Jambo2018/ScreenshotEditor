# ScreenshotEditor Refactoring Audit (2026-04-18)

## Why this refactor is necessary
The current project has reached a point where usability and maintainability are both poor, especially on iPhone and iPad. The problem is no longer isolated UI polish; the product flow, view composition, and state management are all coupled too tightly.

## Current diagnosis

### 1. Product flow is unclear
The app currently mixes empty state, editing state, export state, share state, capture guidance, and platform-specific import flows directly in the main screens. This causes users to see different mental models on macOS vs iOS.

### 2. Mobile adaptation is structurally wrong
The iPhone/iPad layouts are still derived from desktop concepts:
- desktop-like control density is being forced into mobile space
- the preview area loses priority
- bottom tools and inline controls compete for height
- iPhone is treated like a compressed desktop editor instead of a native full-screen editor

### 3. State management is oversized
Key files are too large and hold too many responsibilities:
- `ScreenshotEditor/Models/AppState.swift`: 1108 lines
- `ScreenshotEditor/Views/CanvasView.swift`: 555 lines
- `ScreenshotEditor/Views/ControlPanelView.swift`: 750 lines
- `ScreenshotEditor/Views/ContentView.swift`: 294 lines

`AppState` currently mixes:
- document state
- background styling
- export state
- capture/import state
- platform branching
- annotation state
- view-level UI flags

### 4. Platform branching is leaking into screen design
The project uses many `#if os(...)` branches inside shared screens. This is acceptable for service bridging, but not for top-level page composition.

### 5. UI tokens are not centralized
Spacing, font sizes, button sizes, panel heights, and compact-mode special cases are distributed across views using local constants and one-off numbers. This makes visual consistency almost impossible.

## Must-keep capabilities
These are core and must survive the refactor:
1. Import image
2. macOS screen capture
3. iOS/iPadOS screenshot guidance/import path
4. Preview equals export
5. Background styling
6. Annotation tools
7. Export
8. Share to other apps

## Cut / defer list
The following should be removed, simplified, or deferred during refactor:
- repeated entry points for the same action
- layout-specific micro tweaks before architecture is stable
- hidden/conditional controls that only exist to patch one platform
- non-essential visual variations that increase branching cost
- any new feature work unrelated to the main workflow

## Target user flow

### Empty state
- Primary actions: Capture / Import
- Secondary guidance text
- Preview region is dominant

### Editing state
- Preview canvas remains the largest area
- Tools are grouped by role instead of by legacy placement
- Export/share are always predictable and easy to reach

### Output state
- Export and share use the same rendered pipeline
- Success/failure messaging is explicit

## Target layout strategy

### macOS
- large preview canvas
- fixed-width right inspector
- toolbar-level share/export affordances

### iPad
- preview-first layout
- persistent lower tool region or split layout depending on size class/orientation
- clear separation between edit controls and actions

### iPhone
- full-screen preview-first editor
- bottom action bar for primary actions
- compact tool trays/panels designed specifically for phone
- no desktop inspector metaphor

## Technical refactor direction

### State split
`AppState` should be decomposed into:
- `EditorDocument`
- `CanvasStyleState`
- `ExportState`
- `ImportCaptureState`
- `AppShellState`

### UI split
Current screens should be reorganized into:
- `DesktopEditorScreen`
- `TabletEditorScreen`
- `PhoneEditorScreen`

Shared reusable parts should include:
- `PreviewCanvas`
- `ImportActions`
- `BackgroundPicker`
- `AdjustmentPanel`
- `AnnotationToolbar`
- `ExportActions`

### Platform services
Platform-specific behavior should move behind service wrappers:
- `PlatformImportService`
- `PlatformCaptureService`
- `PlatformShareService`

## Acceptance criteria for the refactor
The refactor is only done when:
1. iPhone/iPad/macOS each have a coherent native layout
2. preview/export parity remains intact
3. `AppState` is no longer the global dumping ground
4. new UI changes do not require cross-platform page hacks
5. import → edit → export/share is stable on every platform

## Phase order
1. Audit and blueprint
2. Information architecture redesign
3. State/service split
4. Multi-platform screen rebuild
5. Design token system
6. Tests and regression verification
