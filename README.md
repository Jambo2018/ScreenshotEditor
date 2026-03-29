# Screenshot Editor

A macOS screenshot editing app similar to Xnapper.

**Learning Project**: Built with SwiftUI + Core Image

## Features (Planned)

### MVP (v1.0)
- [x] Project scaffold
- [ ] Drag & drop screenshot import
- [ ] Gradient background presets (10-20)
- [ ] Solid color backgrounds
- [ ] Blur, padding, corner radius controls
- [ ] Shadow, border toggles
- [ ] Device frame overlay (iPhone + MacBook)
- [ ] Export to PNG/JPG/WebP
- [ ] Auto-copy to clipboard

### Post-MVP (v2.0)
- [ ] Batch export
- [ ] iCloud sync for history
- [ ] More device frames
- [ ] Custom image backgrounds
- [ ] Text annotations
- [ ] Arrow/shape tools

## Tech Stack

- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Image Processing**: Core Image / Core Graphics
- **Deployment**: macOS 14.0+
- **Distribution**: Mac App Store (optional)

## Getting Started

### Requirements
- Xcode 15.0+
- macOS 14.0+

### Build
```bash
cd ~/Desktop/ScreenshotEditor
open ScreenshotEditor.xcodeproj
```

Then in Xcode:
1. Select the ScreenshotEditor scheme
2. Press ⌘R to run

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
├── ViewModels/                  # (future)
├── Utilities/                   # (future)
└── Assets.xcassets/
```

## Design Doc

See: `~/.gstack/projects/jambo2018-js-notes/designs/screenshot-app-design-*.md`

## Learning Goals

- [ ] Master SwiftUI basics (layout, state management)
- [ ] Understand macOS App lifecycle
- [ ] Learn Core Image for image processing
- [ ] Implement system-level integrations (menu bar, shortcuts)
- [ ] Ship a working Mac App Store product

## License

MIT
