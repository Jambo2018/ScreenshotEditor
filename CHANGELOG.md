# Changelog

All notable changes to this project will be documented in this file.

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
