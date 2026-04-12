//
//  SettingsView.swift
//  ScreenshotEditor
//
//  App settings window
//

#if os(macOS)
import SwiftUI

struct SettingsView: View {
    // MARK: - Export Settings
    @AppStorage("autoCopyToClipboard") private var autoCopyToClipboard = true
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "png"
    @AppStorage("includeDateInFilename") private var includeDateInFilename = true
    @AppStorage("defaultQuality") private var defaultQuality: Double = 0.9
    @AppStorage("showExportPanel") private var showExportPanel = true
    
    // MARK: - Appearance Settings
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("accentColor") private var accentColor = "blue"
    
    // MARK: - Capture Settings
    @AppStorage("captureDelay") private var captureDelay: Double = 0
    @AppStorage("showCursorInCapture") private var showCursorInCapture = false
    
    // MARK: - Hotkeys (stored as strings)
    @AppStorage("hotkeyCapture") private var hotkeyCapture = "⌘⇧K"
    @AppStorage("hotkeyImport") private var hotkeyImport = "⌘O"
    @AppStorage("hotkeyExport") private var hotkeyExport = "⌘E"
    
    var body: some View {
        Form {
            // MARK: - Export Section
            Section("Export") {
                Toggle("Auto-copy to clipboard", isOn: $autoCopyToClipboard)
                    .help("Automatically copy exported images to clipboard")

                Picker("Default Format", selection: $defaultExportFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpeg")
                    Text("WebP").tag("webp")
                }
                
                if defaultExportFormat == "jpeg" || defaultExportFormat == "webp" {
                    Slider(value: $defaultQuality, in: 0.5...1.0, step: 0.05) {
                        Text("Quality: \(Int(defaultQuality * 100))%")
                    }
                }

                Toggle("Include date in filename", isOn: $includeDateInFilename)
                
                Toggle("Show save panel", isOn: $showExportPanel)
                    .help("Show save panel on export (disable for quick export to default location)")
            }
            
            // MARK: - Appearance Section
            Section("Appearance") {
                Picker("Appearance", selection: $appearanceMode) {
                    Label("System", systemImage: "cpu")
                        .tag("system")
                    Label("Light", systemImage: "sun.max")
                        .tag("light")
                    Label("Dark", systemImage: "moon")
                        .tag("dark")
                }
                .pickerStyle(.segmented)
                
                Picker("Accent Color", selection: $accentColor) {
                    Label("Blue", systemImage: "circle.fill")
                        .tag("blue")
                        .foregroundColor(.blue)
                    Label("Purple", systemImage: "circle.fill")
                        .tag("purple")
                        .foregroundColor(.purple)
                    Label("Green", systemImage: "circle.fill")
                        .tag("green")
                        .foregroundColor(.green)
                    Label("Orange", systemImage: "circle.fill")
                        .tag("orange")
                        .foregroundColor(.orange)
                    Label("Red", systemImage: "circle.fill")
                        .tag("red")
                        .foregroundColor(.red)
                }
            }

            // MARK: - Capture Section
            Section("Screen Capture") {
                Stepper("Capture delay: \(Int(captureDelay))s", value: $captureDelay, in: 0...5, step: 1)
                    .help("Delay before capturing screen (useful for menu hover)")
                
                Toggle("Show cursor in capture", isOn: $showCursorInCapture)
                    .help("Include mouse cursor in screen captures")
            }
            
            // MARK: - Keyboard Shortcuts Section
            Section("Keyboard Shortcuts") {
                HStack {
                    Text("Capture Screen")
                    Spacer()
                    TextField("Hotkey", text: $hotkeyCapture)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .help("Use format: ⌘⇧K (Cmd+Shift+K)")
                }
                
                HStack {
                    Text("Import")
                    Spacer()
                    TextField("Hotkey", text: $hotkeyImport)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Export")
                    Spacer()
                    TextField("Hotkey", text: $hotkeyExport)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                Button("Reset to Defaults") {
                    hotkeyCapture = "⌘⇧K"
                    hotkeyImport = "⌘O"
                    hotkeyExport = "⌘E"
                }
            }

            // MARK: - About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.4 (Alpha)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("Learning Project")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("GitHub")
                    Spacer()
                    Link("ScreenshotEditor", destination: URL(string: "https://github.com/jambo2018/ScreenshotEditor")!)
                        .foregroundColor(.blue)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
        .onChange(of: appearanceMode) { _, newValue in
            applyAppearanceMode(newValue)
        }
    }
    
    private func applyAppearanceMode(_ mode: String) {
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil // System default
        }
    }
}

#Preview {
    SettingsView()
}
#endif
