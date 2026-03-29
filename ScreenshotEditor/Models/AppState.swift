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
    @Published var blurAmount: Double = 0
    @Published var padding: Double = 40
    @Published var cornerRadius: Double = 12

    // Decoration settings
    @Published var showShadow: Bool = true
    @Published var showBorder: Bool = false
    @Published var deviceFrame: DeviceFrame? = nil

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
        print("[HotKey] Setting up hotkey listener...")

        // Check accessibility permission
        if !GlobalHotKeyMonitor.hasAccessibilityPermission() {
            print("[HotKey] WARNING: Accessibility permission not granted!")
            print("[HotKey] Please grant accessibility permission in System Settings > Privacy & Security > Accessibility")
        } else {
            print("[HotKey] Accessibility permission granted")
        }

        hotKeyMonitor = GlobalHotKeyMonitor()
        hotKeyMonitor?.register(
            key: .k,
            modifiers: [.command, .shift]
        ) { [weak self] in
            print("[HotKey] Hotkey callback triggered!")
            self?.startScreenCapture()
        }
        print("[HotKey] Hotkey registered: Cmd+Shift+K")
    }

    func startScreenCapture() {
        guard let screen = NSScreen.main else { return }

        // Prevent multiple overlays
        if captureOverlayWindow != nil {
            print("[HotKey] Overlay already visible, ignoring")
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
            self.captureOverlayWindow = CaptureOverlayWindow(screen: screen)

            // Weak self to avoid retain cycles
            self.captureOverlayWindow?.onCaptureConfirmed = { [weak self] rect in
                self?.captureRegion(rect)
                // Always reset state on main thread, even if captureRegion fails
                DispatchQueue.main.async {
                    self?.captureOverlayWindow?.closeOverlay()
                    self?.captureOverlayWindow = nil
                    self?.isCapturing = false
                }
            }

            self.captureOverlayWindow?.onCaptureCancelled = { [weak self] in
                DispatchQueue.main.async {
                    self?.captureOverlayWindow?.closeOverlay()
                    self?.captureOverlayWindow = nil
                    self?.isCapturing = false
                }
            }

            // Timeout safety: force close after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let self = self,
                      let overlay = self.captureOverlayWindow else { return }
                print("[HotKey] Timeout - forcing overlay close")
                overlay.closeOverlay()
                self.captureOverlayWindow = nil
                self.isCapturing = false
            }
        }
    }

    private func captureRegion(_ rect: CGRect) {
        guard let image = ScreenCapturer.captureRegion(rect) else {
            errorMessage = "Failed to capture screen"
            // Still reset state even on capture failure
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

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.screenshots.insert(screenshot, at: 0)
            self.selectedScreenshotId = screenshot.id
            // Note: isCapturing is reset by the caller (onCaptureConfirmed handler)
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

    func exportCurrent(format: ImageFormat = .png) {
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
                    backgroundImage: nil, // TODO: Add backgroundImage support
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
                    self.showSavePanel(data: data, format: format)
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

    private func showSavePanel(data: Data, format: ImageFormat) {
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
                self.copyToClipboard(data: data)
                self.errorMessage = nil
                print("Success: Saved to \(url.path) and copied to clipboard")
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
