# Changelog

All notable changes to this project will be documented in this file.

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
