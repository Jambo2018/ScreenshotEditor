# ScreenshotEditor State Model Split (2026-04-18)

## Goal
Break the previous `AppState` monolith into focused state domains without forcing a full UI rewrite in the same commit.

## Current split

### `EditorDocumentState`
Owns:
- screenshots
- current selection
- annotations
- annotation tool attributes

### `CanvasStyleState`
Owns:
- background configuration
- blur / padding / corner radius
- device frame
- export ratio

### `ExportWorkflowState`
Owns:
- export progress
- batch export progress
- clipboard/export preferences
- share sheet file

### `ImportCaptureState`
Owns:
- import picker presentation
- photo picker presentation
- background image picker presentation
- capture guide presentation
- capture activity state

### `EditorShellState`
Owns:
- error presentation
- shell-level flags such as annotation panel visibility
- temporary shell interaction flags

## Transitional rule
`AppState` remains the composition root for now and forwards child-state changes so existing views can keep using the same environment object while the rest of the UI is refactored incrementally.
