//
//  ContentView.swift
//  ScreenshotEditor
//
//  Main content view with three-column layout
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showErrorSheet: Bool = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Left sidebar - Screenshot list
            ScreenshotListView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 280)
        } detail: {
            HSplitView {
                // Center - Canvas area
                CanvasView()

                // Right panel - Controls
                ControlPanelView()
                    .frame(minWidth: 250, maxWidth: 320)
            }
        }
        .onChange(of: appState.errorMessage) { _, newValue in
            showErrorSheet = newValue != nil
        }
        .toolbar {
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
