//
//  SettingsView.swift
//  ScreenshotEditor
//
//  App settings window
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoCopyToClipboard") private var autoCopyToClipboard = true
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "png"
    @AppStorage("includeDateInFilename") private var includeDateInFilename = true

    var body: some View {
        Form {
            Section("Export") {
                Toggle("Auto-copy to clipboard", isOn: $autoCopyToClipboard)
                    .help("Automatically copy exported images to clipboard")

                Picker("Default Format", selection: $defaultExportFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpeg")
                    Text("WebP").tag("webp")
                }

                Toggle("Include date in filename", isOn: $includeDateInFilename)
            }

            Section("Shortcuts") {
                HStack {
                    Text("Import")
                    Spacer()
                    Text("⌘O")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Export")
                    Spacer()
                    Text("⌘E")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Save")
                    Spacer()
                    Text("⌘S")
                        .foregroundColor(.secondary)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Alpha)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("Learning Project")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 250)
    }
}

#Preview {
    SettingsView()
}
