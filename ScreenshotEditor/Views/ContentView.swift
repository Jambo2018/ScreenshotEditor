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
                Button(action: { appState.shareCurrent() }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(!appState.hasScreenshot || appState.isExporting)
                .help("Share to other apps")
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
