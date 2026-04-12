# Changelog

All notable changes to this project will be documented in this file.

## [0.1.12.0] - 2026-04-12

### Added
- Added multiplatform project configuration so the main app target now appears for macOS, iPhone, and iPad simulator destinations.
- Added platform-neutral image abstractions plus iOS file-import and share-sheet presentation flows.
- Added iPhone/iPad full-screen editing flow with an in-canvas action bar and a bottom editing dock.
- Added iOS photo-library import plus an in-app capture guide so screenshot intake is still discoverable on mobile.

### Changed
- Refactored shared rendering, screenshot storage, and canvas preview code to use cross-platform image helpers instead of direct AppKit-only types.
- Routed import and export/share actions through app state so the same editor workflow works on macOS and iOS/iPadOS.
- Gated macOS-only capture, hotkey, pin-window, and settings implementations behind platform conditionals to keep the shared target compiling cleanly on iPhone and iPad.
- Moved iPhone/iPad adjustments into a dedicated mobile sheet opened from the bottom bar, while keeping the desktop fixed-width inspector on macOS.

### Fixed
- Fixed the toolbar share popover anchor on macOS so the share sheet is positioned from the actual share button.
- Fixed the previous mobile dead-end where import and screenshot actions were not exposed clearly inside the iOS editing flow.

## [0.1.11.0] - 2026-04-12

### Added
- Added a system share action in the top-right toolbar that shares the current rendered image to other apps via the macOS share sheet.
- Added an editing bottom action bar that contains capture, import, and annotation tool selection during active editing.

### Changed
- Moved capture and import actions out of the toolbar and into the main canvas experience.
- Converted the editing toolbar from a floating overlay into a real bottom operation bar so it no longer covers the preview.
- Simplified the annotation side panel so it focuses on tool settings and annotation management instead of duplicating tool picking.
- Prepared the app entry flow for future iPhone/iPad support by routing capture/import through higher-level request methods.

### Fixed
- Ensured sharing uses the same rendering pipeline as export so shared results match the preview.

## [0.1.10.0] - 2026-04-12

### Fixed
- Unified preview and export rendering through a shared `ImageExporter` pipeline so canvas padding, background blur, aspect ratio, and device frame output match the exported image more closely.
- Applied blur consistently to color and image backgrounds in export rendering instead of only in the SwiftUI preview path.

### Changed
- Simplified the main layout to a two-pane editor with only the preview canvas and right-side editing controls.
- Reworked image import/capture/drop behavior to replace the current working image instead of maintaining a left-side import history list.
- Reset annotations when switching to a newly imported or captured image to keep editing state aligned with the single-image workflow.

### Added
- Added empty-state actions in the preview area for “去截图” and “导入图片”.
- Added regression coverage for shared render sizing and single-image state management.

## [0.1.9.0] - 2026-03-30

### Added
- Annotation tools: text, arrow, rectangle, ellipse, highlight, blur
- Annotation panel for tool selection and settings
- Canvas annotation rendering with drag-to-edit support
- Text annotations with customizable font size and color
- Shape annotations (arrow, rectangle) with color and stroke width control
- Brush annotations (highlight, blur) with size and opacity control

## [0.1.8.0] - 2026-03-30

### Fixed
- Export output now matches CanvasView preview — corrected effect order (corner radius, shadow, border applied to source image before compositing)

## [0.1.7.0] - 2026-03-30

### Fixed
- Capture overlay deadlock fixed by using singleton NSPanel instead of per-capture window

## [0.1.6.0] - 2026-03-30

### Fixed
- Capture overlay deadlock on timeout - moved close() to async dispatch to avoid blocking main thread

## [0.1.5.0] - 2026-03-30

### Fixed
- Capture overlay timeout handler crash - removed direct callback invocation to prevent double-execution

## [0.1.4.0] - 2026-03-29

### Added
- Custom image background support - users can select any image as background with blur control

## [0.1.3.0] - 2026-03-29

### Added
- Device frame overlay preview in CanvasView with iPhone (notch, home indicator) and MacBook (chin) styles

## [0.1.2.0] - 2026-03-29

### Fixed
- Auto-copy to clipboard toggle now works correctly — respects user preference in export

## [0.1.1.0] - 2026-03-29

### Changed
- Cleanup debug logging in AppState and CaptureOverlayWindow
- Improved capture overlay callback handling for better resource cleanup
- Made `isSelecting` property internal for callback handler compatibility
- Better window lifecycle management in CaptureOverlayWindow (explicit cleanup on confirm/cancel)
- Removed redundant print statements from hotkey setup and capture flow

## [0.1.0.0] - 2026-03-29

### Added
- Screen capture functionality with global hotkey (Cmd+Shift+K)
- Region selection overlay for capturing specific screen areas
- Screen recording permission handling
- New utilities: `GlobalHotKeyMonitor`, `ScreenCapturer`, `CaptureOverlayWindow`
- Export format support (PNG, JPEG, WebP fallback)
- Background options: gradient, solid color, blur, image
- Decoration options: shadow, border, corner radius
- Drag-and-drop image import
- Keyboard shortcuts for capture, import, and export

### Changed
- `Screenshot.sourceURL` is now optional to support captured images without file URLs
- ImageExporter expanded with full background creation and effects pipeline
