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
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Capture Screen...") {
                    appState.requestScreenCapture()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                Button("Import Screenshot...") {
                    appState.requestImageImport()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Share...") {
                    appState.shareCurrent()
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
        #else
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        #endif
    }
}

// MARK: - App Delegate

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Activate the app on launch to receive global events
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
