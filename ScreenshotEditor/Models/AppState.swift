//
//  AppState.swift
//  ScreenshotEditor
//
//  Main app state manager using ObservableObject pattern
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import CoreImage

class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var screenshots: [Screenshot] = []
    @Published var selectedScreenshotId: UUID?
    @Published var isExporting: Bool = false
    @Published var errorMessage: String?
    @Published var isCapturing: Bool = false

    // Screen capture
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var captureOverlayWindow: CaptureOverlayWindow?

    // Background settings
    @Published var backgroundType: BackgroundType = .gradient
    @Published var selectedGradient: GradientPreset = .ocean
    @Published var selectedColor: Color = .white
    @Published var backgroundImage: NSImage?
    @Published var blurAmount: Double = 0
    @Published var padding: Double = 40
    @Published var cornerRadius: Double = 12

    // Decoration settings
    @Published var showShadow: Bool = true
    @Published var showBorder: Bool = false
    @Published var deviceFrame: DeviceFrame = .none

    // Export settings
    @Published var autoCopyToClipboard: Bool = true

    // MARK: - Computed Properties

    var selectedScreenshot: Screenshot? {
        screenshots.first { $0.id == selectedScreenshotId }
    }

    var hasScreenshot: Bool {
        selectedScreenshot != nil
    }

    // MARK: - Initialization

    init() {
        loadFromiCloud()
        setupHotKey()
    }

    // MARK: - Screen Capture Setup

    private func setupHotKey() {
        // Check accessibility permission
        if !GlobalHotKeyMonitor.hasAccessibilityPermission() {
            #if DEBUG
            print("[HotKey] WARNING: Accessibility permission not granted!")
            #endif
        }

        hotKeyMonitor = GlobalHotKeyMonitor()
        hotKeyMonitor?.register(
            key: .k,
            modifiers: [.command, .shift]
        ) { [weak self] in
            self?.startScreenCapture()
        }
    }

    func startScreenCapture() {
        guard let screen = NSScreen.main else { return }

        // Prevent multiple overlays
        if captureOverlayWindow != nil {
            return
        }

        // Request permission if needed
        Task { @MainActor in
            if !ScreenCapturer.hasScreenRecordingPermission() {
                let granted = await ScreenCapturer.requestPermission()
                if !granted {
                    self.errorMessage = "Screen recording permission denied"
                    self.isCapturing = false
                    return
                }
            }

            self.isCapturing = true
            let overlayWindow = CaptureOverlayWindow(screen: screen)
            self.captureOverlayWindow = overlayWindow

            // Capture overlay callbacks
            overlayWindow.onCaptureConfirmed = { [weak self] rect in
                guard let self = self else { return }

                // Reset state
                self.captureOverlayWindow = nil
                self.isCapturing = false

                // Activate main app window
                NSApp.activate(ignoringOtherApps: true)

                // Capture on background thread
                self.captureRegion(rect)
            }

            overlayWindow.onCaptureCancelled = { [weak self] in
                guard let self = self else { return }

                // Reset state
                self.captureOverlayWindow = nil
                self.isCapturing = false

                // Activate main app window
                NSApp.activate(ignoringOtherApps: true)
            }

            // Timeout safety: force close after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self,
                      let overlay = self.captureOverlayWindow else { return }
                overlay.onCaptureCancelled?()
                self.captureOverlayWindow = nil
                self.isCapturing = false
            }
        }
    }

    // MARK: - Screen Capture

    private func captureRegion(_ rect: CGRect) {
        // Capture on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let image = ScreenCapturer.captureRegion(rect) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to capture screen"
                }
                return
            }

            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))

            let screenshot = Screenshot(
                id: UUID(),
                name: "Screenshot-\(Date().formatted(.dateTime.hour().minute().second()))",
                sourceURL: nil,
                createdAt: Date(),
                image: nsImage
            )

            // Update UI on main thread
            DispatchQueue.main.async {
                self.screenshots.insert(screenshot, at: 0)
                self.selectedScreenshotId = screenshot.id
            }
        }
    }

    // MARK: - Actions

    func importScreenshot() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a screenshot to edit"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.loadImage(from: url)
        }
    }

    func loadImage(from url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            errorMessage = "Failed to load image"
            return
        }

        let screenshot = Screenshot(
            id: UUID(),
            name: url.lastPathComponent,
            sourceURL: url,
            createdAt: Date(),
            image: image
        )

        DispatchQueue.main.async {
            self.screenshots.insert(screenshot, at: 0)
            self.selectedScreenshotId = screenshot.id
        }
    }

    func exportCurrent(format: ImageFormat = .png, copyToClipboard: Bool? = nil) {
        guard let screenshot = selectedScreenshot,
              let image = screenshot.image else {
            errorMessage = "No screenshot selected"
            print("[Export] ERROR: No screenshot or image available")
            return
        }

        print("[Export] Starting export from AppState")
        print("[Export] Background: \(backgroundType), Gradient: \(selectedGradient.name)")
        print("[Export] Settings: blur=\(blurAmount), padding=\(padding), corner=\(cornerRadius)")

        isExporting = true

        let currentBackgroundType = backgroundType
        let currentGradient = selectedGradient
        let currentSolidColor = selectedColor
        let currentBlurAmount = blurAmount
        let currentPadding = padding
        let currentCornerRadius = cornerRadius
        let currentShowShadow = showShadow
        let currentShowBorder = showBorder
        let currentDeviceFrame = deviceFrame
        let shouldCopyToClipboard = copyToClipboard ?? autoCopyToClipboard

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("[Export] ERROR: Self is nil in async block")
                return
            }

            do {
                // Export image with current settings
                let data = try ImageExporter.exportImage(
                    sourceImage: image,
                    backgroundType: currentBackgroundType,
                    gradient: currentGradient,
                    solidColor: currentSolidColor,
                    backgroundImage: self.backgroundImage,
                    blurAmount: currentBlurAmount,
                    padding: currentPadding,
                    cornerRadius: currentCornerRadius,
                    showShadow: currentShowShadow,
                    showBorder: currentShowBorder,
                    deviceFrame: currentDeviceFrame,
                    format: format
                )

                print("[Export] Export succeeded, data size: \(data.count) bytes")

                DispatchQueue.main.async {
                    self.isExporting = false
                    self.showSavePanel(data: data, format: format, copyToClipboard: shouldCopyToClipboard)
                }
            } catch {
                print("[Export] ERROR: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.errorMessage = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func showSavePanel(data: Data, format: ImageFormat, copyToClipboard: Bool = true) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = "Screenshot-\(Date().formatted(.dateTime.year().month().day().hour().minute()))\(format.fileExtension)"
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.message = "Choose where to save your screenshot"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }

            do {
                try data.write(to: url)
                if copyToClipboard {
                    self.copyToClipboard(data: data)
                    self.errorMessage = nil
                    print("Success: Saved to \(url.path) and copied to clipboard")
                } else {
                    self.errorMessage = nil
                    print("Success: Saved to \(url.path) (clipboard disabled)")
                }
            } catch {
                self.errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    private func copyToClipboard(data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    func deleteScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
        if selectedScreenshotId == screenshot.id {
            selectedScreenshotId = screenshots.first?.id
        }
    }

    // MARK: - Persistence

    private func loadFromiCloud() {
        // TODO: Implement iCloud sync
        // For now, load from local documents directory
    }

    private func saveTtoiCloud() {
        // TODO: Implement iCloud sync
    }
}

// MARK: - Supporting Types

enum BackgroundType: String, CaseIterable {
    case gradient = "Gradient"
    case solid = "Solid Color"
    case blur = "Blur"
    case image = "Image"
}

struct GradientPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colors: [Color]

    static let ocean = GradientPreset(name: "Ocean", colors: [.blue, .purple])
    static let sunset = GradientPreset(name: "Sunset", colors: [.orange, .pink])
    static let forest = GradientPreset(name: "Forest", colors: [.green, .teal])
    static let fire = GradientPreset(name: "Fire", colors: [.red, .yellow])
    static let midnight = GradientPreset(name: "Midnight", colors: [.indigo, .black])

    static let presets = [ocean, sunset, forest, fire, midnight]
}

enum DeviceFrame: String, CaseIterable {
    case none = "None"
    case iphone = "iPhone"
    case macbook = "MacBook"
}

// MARK: - ImageFormat Extension

extension ImageFormat {
    var contentType: UTType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .webp:
            return .png // Fallback
        }
    }

    var fileExtension: String {
        switch self {
        case .png:
            return ".png"
        case .jpeg:
            return ".jpg"
        case .webp:
            return ".png" // Fallback
        }
    }
}
