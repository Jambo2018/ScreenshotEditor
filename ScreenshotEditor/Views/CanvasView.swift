//
//  CanvasView.swift
//  ScreenshotEditor
//
//  Center canvas showing the screenshot with background
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
                        .onDrag {
                            // Support dragging the edited screenshot
                            itemProviderForImage(image)
                        }

                    // Annotation layer
                    AnnotationLayerView(sourceImage: image)
                        .environmentObject(appState)
                }
                .aspectRatio(canvasAspectRatio(for: image), contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
                    // Support dropping screenshots onto the canvas
                    handleDrop(providers: providers)
                    return true
                }

                CompactCanvasToolbar()
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
        case .color:
            if appState.activeGradientColors.count == 1 {
                appState.activeGradientColors[0]
                    .blur(radius: appState.blurAmount)
            } else {
                LinearGradient(
                    colors: appState.activeGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: appState.blurAmount)
            }

        case .blur:
            Color.clear
                .blur(radius: appState.blurAmount)

        case .image:
            if let backgroundImage = appState.backgroundImage {
                Image(nsImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: appState.blurAmount)
            } else {
                Color.secondary.opacity(0.2)
            }
        }
    }

    private func canvasAspectRatio(for image: NSImage) -> CGFloat {
        if let ratio = appState.resolvedAspectRatioValue {
            return ratio
        }

        let width = image.size.width + (appState.padding * 2)
        let height = image.size.height + (appState.padding * 2)
        guard height > 0 else { return 1 }
        return width / height
    }

    private func itemProviderForImage(_ image: NSImage) -> NSItemProvider {
        // Convert NSImage to PNG data for drag export
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
                let itemProvider = NSItemProvider(item: pngData as NSSecureCoding, typeIdentifier: UTType.png.identifier)
                return itemProvider
            }
        }
        return NSItemProvider()
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            // Try to load image from drop
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error = error {
                    DispatchQueue.main.async {
                        appState.errorMessage = "Failed to load image: \(error.localizedDescription)"
                    }
                    return
                }

                if let imageData = item as? Data,
                   let nsImage = NSImage(data: imageData) {
                    DispatchQueue.main.async {
                        // Create new screenshot from dropped image
                        let screenshot = Screenshot(
                            id: UUID(),
                            name: "Dropped Image \(Date().timeIntervalSince1970)",
                            sourceURL: nil,
                            createdAt: Date(),
                            image: nsImage
                        )
                        appState.screenshots.append(screenshot)
                        appState.selectedScreenshotId = screenshot.id
                    }
                } else if let url = item as? URL {
                    // Handle file URL drops
                    appState.loadImage(from: url)
                }
            }
            break // Only handle first provider
        }
    }
}

// MARK: - Canvas Action Button

struct CompactCanvasToolbar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            CompactCanvasToggle(
                icon: "circlebadge",
                title: "Corner",
                isActive: appState.cornerRadius > 0
            ) {
                withAnimation {
                    appState.cornerRadius = appState.cornerRadius > 0 ? 0 : 12
                }
            }

            CompactCanvasToggle(
                icon: "shadow",
                title: "Shadow",
                isActive: appState.showShadow
            ) {
                withAnimation {
                    appState.showShadow.toggle()
                }
            }

            CompactCanvasToggle(
                icon: "square",
                title: "Border",
                isActive: appState.showBorder
            ) {
                withAnimation {
                    appState.showBorder.toggle()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

struct CompactCanvasToggle: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

// MARK: - Device Frame Overlay

extension CanvasView {
    @ViewBuilder
    private func deviceFrameOverlay(for image: NSImage, frame: DeviceFrame) -> some View {
        switch frame {
        case .none:
            EmptyView()

        case .iphone:
            iPhoneFrameOverlay(for: image)

        case .macbook:
            MacBookFrameOverlay(for: image)
        }
    }

    private func iPhoneFrameOverlay(for image: NSImage) -> some View {
        ZStack {
            // Device body
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)

            // Screen area with image
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .overlay(
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .clipped()
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 30)

            // Top notch
            Capsule()
                .fill(Color.black)
                .frame(width: 100, height: 20)
                .offset(y: -140)

            // Bottom home indicator
            Capsule()
                .fill(Color.black.opacity(0.8))
                .frame(width: 100, height: 4)
                .offset(y: 140)
        }
        .aspectRatio(9 / 19.5, contentMode: .fit)
    }

    private func MacBookFrameOverlay(for image: NSImage) -> some View {
        ZStack {
            // Device body (dark gray)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.8))

            // Screen area
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .clipped()
                )
                .padding(.horizontal, 15)
                .padding(.top, 20)
                .padding(.bottom, 40) // MacBook chin

            // Bottom chin detail line
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(height: 1)
                .padding(.horizontal, 30)
                .offset(y: 100)
        }
        .aspectRatio(16 / 10, contentMode: .fit)
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
