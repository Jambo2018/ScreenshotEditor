//
//  ScreenshotEditorApp.swift
//  ScreenshotEditor
//
//  A macOS screenshot editing app similar to Xnapper
//  Learning project: SwiftUI + Core Image
//

import SwiftUI

@main
struct ScreenshotEditorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Screenshot...") {
                    appState.importScreenshot()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Export...") {
                    appState.exportCurrent()
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
