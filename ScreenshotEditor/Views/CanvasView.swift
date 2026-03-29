//
//  CanvasView.swift
//  ScreenshotEditor
//
//  Center canvas showing the screenshot with background
//

import SwiftUI

struct CanvasView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            if let screenshot = appState.selectedScreenshot,
               let image = screenshot.image {

                // Canvas area with background
                ZStack {
                    // Background
                    backgroundView

                    // Screenshot with effects
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(appState.cornerRadius)
                        .shadow(color: appState.showShadow ? Color.black.opacity(0.3) : Color.clear,
                                radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: appState.cornerRadius)
                                .stroke(appState.showBorder ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                        .padding(appState.padding)

                    // Device frame overlay (future)
                    if appState.deviceFrame != .none {
                        // TODO: Implement device frame overlay
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))

                // Quick action toolbar
                HStack(spacing: 12) {
                    CanvasActionButton(icon: "circlebadge", title: "Corner") {
                        // Toggle corner radius
                        withAnimation {
                            appState.cornerRadius = appState.cornerRadius > 0 ? 0 : 12
                        }
                    }

                    CanvasActionButton(icon: "shadow", title: "Shadow") {
                        withAnimation {
                            appState.showShadow.toggle()
                        }
                    }

                    CanvasActionButton(icon: "square", title: "Border") {
                        withAnimation {
                            appState.showBorder.toggle()
                        }
                    }

                    CanvasActionButton(icon: "macbook.and.iphone", title: "Frame") {
                        // Toggle device frame
                        withAnimation {
                            if appState.deviceFrame == .none {
                                appState.deviceFrame = .iphone
                            } else if appState.deviceFrame == .iphone {
                                appState.deviceFrame = .macbook
                            } else {
                                appState.deviceFrame = .none
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))

            } else {
                // Welcome / Empty state
                WelcomeView()
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch appState.backgroundType {
        case .gradient:
            LinearGradient(
                colors: appState.selectedGradient.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: appState.blurAmount)

        case .solid:
            appState.selectedColor

        case .blur:
            Color.clear
                .blur(radius: appState.blurAmount)

        case .image:
            // TODO: Custom image background
            Color.secondary.opacity(0.2)
        }
    }
}

// MARK: - Canvas Action Button

struct CanvasActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 50, height: 50)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Welcome to Screenshot Editor")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Drag and drop a screenshot to get started")
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Label("Import", systemImage: "keyboard.command")
                Label("Export", systemImage: "keyboard.command")
                Label("Save", systemImage: "keyboard.command")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
