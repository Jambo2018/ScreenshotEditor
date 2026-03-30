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
    @State private var showHistoryWindow: Bool = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Left sidebar - Screenshot list
            ScreenshotListView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 280)
        } detail: {
            HSplitView {
                // Center - Canvas area
                CanvasView()

                // Right panel - Controls + Annotation tools
                VStack(spacing: 0) {
                    ControlPanelView()
                        .frame(minWidth: 250, maxWidth: 320)

                    Divider()

                    AnnotationPanelView()
                        .frame(minWidth: 250, maxWidth: 320)
                }
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

            ToolbarItem(placement: .automatic) {
                Button(action: { showHistoryWindow = true }) {
                    Label("History", systemImage: "clock")
                }
                .help("View screenshot history")
            }
        }
        .sheet(isPresented: $showErrorSheet) {
            ErrorView(message: $appState.errorMessage)
        }
        .sheet(isPresented: $showHistoryWindow) {
            HistoryView()
                .environmentObject(appState)
                .frame(width: 800, height: 600)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
