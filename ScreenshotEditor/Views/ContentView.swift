//
//  ContentView.swift
//  ScreenshotEditor
//
//  Main content view with three-column layout
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showErrorSheet: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            CanvasView()

            Divider()

            VStack(spacing: 0) {
                ControlPanelView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 288)
        }
        .onChange(of: appState.errorMessage) { _, newValue in
            showErrorSheet = newValue != nil
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                #if os(macOS)
                ToolbarShareButton(appState: appState)
                #else
                Button(action: { appState.shareCurrent() }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(!appState.hasScreenshot || appState.isExporting)
                .help("Share to other apps")
                #endif
            }
        }
        .sheet(isPresented: $showErrorSheet) {
            ErrorView(message: $appState.errorMessage)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

#if os(macOS)
struct ToolbarShareButton: NSViewRepresentable {
    @ObservedObject var appState: AppState

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(
            systemSymbolName: "square.and.arrow.up",
            accessibilityDescription: "Share"
        )
        button.imagePosition = .imageOnly
        button.controlSize = .large
        button.contentTintColor = .labelColor
        button.target = context.coordinator
        button.action = #selector(Coordinator.didPressShare(_:))
        button.toolTip = "Share to other apps"
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.appState = appState
        nsView.isEnabled = appState.hasScreenshot && !appState.isExporting
    }

    final class Coordinator: NSObject {
        var appState: AppState

        init(appState: AppState) {
            self.appState = appState
        }

        @objc func didPressShare(_ sender: NSButton) {
            appState.shareCurrent(from: sender)
        }
    }
}
#endif
