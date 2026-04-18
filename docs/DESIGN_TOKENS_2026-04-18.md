# ScreenshotEditor Design Tokens (2026-04-18)

## Goal
Phase 4 introduces a shared sizing layer so the refactor no longer depends on scattered magic numbers inside SwiftUI views.

## Shared token groups
- `EditorSpacing`
  - shared spacing ladder from micro to xxxLarge
- `EditorCornerRadius`
  - compact, small, medium, xLarge, panel
- `EditorOpacity`
  - subtle fills, accent fills, toolbar opacity, selection fills, stroke opacity
- `EditorTypography`
  - shared compact labels plus shell/workspace title and subtitle helpers
- `EditorDeviceClass`
  - `phone`, `tablet`, `desktop`
  - owns platform sizing rules for:
    - canvas padding
    - top bar padding
    - action button sizing
    - bottom toolbar density
    - workspace panel widths

## Applied in this phase
- `ContentView.swift`
  - top bars, workspace cards, inspector sizing, shell padding
- `CanvasView.swift`
  - preview padding, welcome actions, bottom editing bar
- `ControlPanelView.swift`
  - compact inline controls, swatches, slider/menu/stepper controls
- `AnnotationPanelView.swift`
  - header spacing, panel spacing, row padding

## Immediate benefit
- compact/regular/desktop sizing now comes from one shared token source
- follow-up layout work can tune density by updating token rules instead of editing every screen separately
