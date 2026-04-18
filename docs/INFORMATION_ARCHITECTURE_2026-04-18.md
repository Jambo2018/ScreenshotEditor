# ScreenshotEditor Information Architecture (2026-04-18)

## Canonical app states

### 1. Empty
- No active screenshot
- Primary intent: import or capture
- Preview region acts as onboarding surface

### 2. Editing
- Active screenshot exists
- Primary intent: adjust canvas, annotate, export, share
- Preview remains dominant and controls are grouped by role

### 3. Exporting
- Active screenshot exists and export is running
- Layout remains stable
- Output actions show processing status rather than changing navigation structure

## Action ownership

### Import / Capture
- Empty state: shown in preview onboarding
- Editing state: shown in the bottom action strip

### Canvas adjustments
- Belong to the tool workspace, not the preview
- Inline on mobile
- Fixed inspector on desktop

### Annotation tools
- Belong to the bottom action strip in editing mode

### Share
- Always a top-level action
- Toolbar on macOS
- Top bar on iPhone/iPad

### Export
- Lives with canvas/output settings, not with navigation chrome

## Platform shells

### Desktop shell
- Preview left
- Fixed inspector right
- Toolbar share entry

### Tablet shell
- Preview-first full canvas
- Top context bar
- Bottom editing workspace with tool controls and action strip

### Phone shell
- Full-screen preview-first editor
- Top context/share bar
- Bottom editing workspace with compact controls

## Immediate implementation rule
The root `ContentView` should only decide:
1. current shell
2. current app state
3. wiring of shared presentation flows

It should not remain the place where every platform-specific layout detail is composed inline.
