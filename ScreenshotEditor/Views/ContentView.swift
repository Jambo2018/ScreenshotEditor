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
        HSplitView {
            CanvasView()

            VStack(spacing: 0) {
                ControlPanelView()
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)

                Divider()

                AnnotationPanelView()
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
            }
        }
        .onChange(of: appState.errorMessage) { _, newValue in
            showErrorSheet = newValue != nil
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.startScreenCapture() }) {
                    Label("Capture", systemImage: "camera.viewfinder")
                }
                .help("Capture screen (⌘⇧K)")
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { appState.importScreenshot() }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import a screenshot (⌘O)")
            }

            ToolbarItem(placement: .automatic) {
                Button(action: { appState.exportCurrent() }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export image (⌘E)")
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
