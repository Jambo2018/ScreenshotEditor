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
    @Published var selectedScreenshotIds: Set<UUID> = [] // For batch selection
    @Published var isExporting: Bool = false
    @Published var isBatchExporting: Bool = false
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
    
    // Annotation tools
    @Published var annotations: [Annotation] = []
    @Published var selectedAnnotationId: UUID?
    @Published var isAddingText = false
    @Published var currentTextColor: Color = .white
    @Published var currentTextSize: Double = 24

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

        exportImages(images: [(image, screenshot.name)], format: format, copyToClipboard: copyToClipboard)
    }
    
    func exportBatch(format: ImageFormat = .png, copyToClipboard: Bool = false) {
        guard !selectedScreenshotIds.isEmpty else {
            errorMessage = "No screenshots selected for batch export"
            return
        }
        
        isBatchExporting = true
        
        var imagesToExport: [(NSImage, String)] = []
        for id in selectedScreenshotIds {
            if let screenshot = screenshots.first(where: { $0.id == id }),
               let image = screenshot.image {
                imagesToExport.append((image, screenshot.name))
            }
        }
        
        guard !imagesToExport.isEmpty else {
            errorMessage = "No valid images to export"
            isBatchExporting = false
            return
        }
        
        exportImages(images: imagesToExport, format: format, copyToClipboard: copyToClipboard)
    }
    
    private func exportImages(images: [(NSImage, String)], format: ImageFormat, copyToClipboard: Bool?) {
        let isBatch = images.count > 1
        
        if isBatch {
            isBatchExporting = true
        } else {
            isExporting = true
        }

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
                if isBatch {
                    // Batch export: save to folder
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "Choose folder for batch export"
                    
                    DispatchQueue.main.async {
                        panel.begin { response in
                            guard response == .OK, let folderURL = panel.url else {
                                DispatchQueue.main.async {
                                    self.isBatchExporting = false
                                }
                                return
                            }
                            
                            var exportedCount = 0
                            for (image, name) in images {
                                do {
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
                                    
                                    let filename = "\(name)_edited\(format.fileExtension)"
                                    let fileURL = folderURL.appendingPathComponent(filename)
                                    try data.write(to: fileURL)
                                    exportedCount += 1
                                } catch {
                                    print("[BatchExport] Failed to export \(name): \(error)")
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.isBatchExporting = false
                                self.errorMessage = nil
                                print("Batch export completed: \(exportedCount)/\(images.count) images")
                            }
                        }
                    }
                } else {
                    // Single export: show save panel
                    let data = try ImageExporter.exportImage(
                        sourceImage: images.first!.0,
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
                }
            } catch {
                print("[Export] ERROR: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.isBatchExporting = false
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
        // Load from local documents directory (iCloud sync placeholder)
        loadFromDocumentsDirectory()
    }
    
    private func loadFromDocumentsDirectory() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let appFolder = documentsPath.appendingPathComponent("ScreenshotEditor", isDirectory: true)
        let metadataFile = appFolder.appendingPathComponent("metadata.json")
        
        // Create folder if not exists
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        // Load metadata if exists
        guard FileManager.default.fileExists(atPath: metadataFile.path),
              let data = try? Data(contentsOf: metadataFile),
              let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Note: Actual screenshot images need to be loaded separately
        // This is a basic implementation - full iCloud sync would use NSUbiquitousKeyValueStore
        print("[Persistence] Loaded metadata from documents directory")
    }

    private func saveToiCloud() {
        // Save to local documents directory (iCloud sync placeholder)
        saveToDocumentsDirectory()
    }
    
    private func saveToDocumentsDirectory() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let appFolder = documentsPath.appendingPathComponent("ScreenshotEditor", isDirectory: true)
        let metadataFile = appFolder.appendingPathComponent("metadata.json")
        
        // Create folder if not exists
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        // Create metadata dictionary
        let metadata: [String: Any] = [
            "version": 1,
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "screenshotCount": screenshots.count,
            "settings": [
                "backgroundType": backgroundType.rawValue,
                "selectedGradient": selectedGradient.name,
                "blurAmount": blurAmount,
                "padding": padding,
                "cornerRadius": cornerRadius,
                "showShadow": showShadow,
                "showBorder": showBorder,
                "deviceFrame": deviceFrame.rawValue,
                "autoCopyToClipboard": autoCopyToClipboard
            ]
        ]
        
        // Write metadata
        if let data = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted) {
            try? data.write(to: metadataFile)
            print("[Persistence] Saved metadata to documents directory")
        }
        
        // Save screenshots as images
        for screenshot in screenshots {
            guard let image = screenshot.image,
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }
            
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                let imageFile = appFolder.appendingPathComponent("\(screenshot.id.uuidString).png")
                try? pngData.write(to: imageFile)
            }
        }
    }

    private func saveTtoiCloud() {
        // Deprecated: Use saveToiCloud instead
        saveToiCloud()
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

    // MARK: - Original Presets (5)
    static let ocean = GradientPreset(name: "Ocean", colors: [.blue, .purple])
    static let sunset = GradientPreset(name: "Sunset", colors: [.orange, .pink])
    static let forest = GradientPreset(name: "Forest", colors: [.green, .teal])
    static let fire = GradientPreset(name: "Fire", colors: [.red, .yellow])
    static let midnight = GradientPreset(name: "Midnight", colors: [.indigo, .black])
    
    // MARK: - New Presets - Warm Tones (5)
    static let peach = GradientPreset(name: "Peach", colors: [.orange, .yellow, .pink])
    static let coral = GradientPreset(name: "Coral", colors: [.red, .orange, .pink])
    static let amber = GradientPreset(name: "Amber", colors: [.yellow, .orange, .red])
    static let rose = GradientPreset(name: "Rose", colors: [.pink, .red, .purple])
    static let honey = GradientPreset(name: "Honey", colors: [.yellow, .orange, .orange])
    
    // MARK: - New Presets - Cool Tones (5)
    static let arctic = GradientPreset(name: "Arctic", colors: [.cyan, .blue, .purple])
    static let mint = GradientPreset(name: "Mint", colors: [.green, .mint, .teal])
    static let lavender = GradientPreset(name: "Lavender", colors: [.purple, .indigo, .pink])
    static let sky = GradientPreset(name: "Sky", colors: [.blue, .cyan, .white])
    static let oceanic = GradientPreset(name: "Oceanic", colors: [.teal, .blue, .indigo])
    
    // MARK: - New Presets - Special (5)
    static let aurora = GradientPreset(name: "Aurora", colors: [.green, .cyan, .purple, .pink])
    static let galaxy = GradientPreset(name: "Galaxy", colors: [.purple, .indigo, .black, .blue])
    static let candy = GradientPreset(name: "Candy", colors: [.pink, .purple, .blue, .green])
    static let sunrise = GradientPreset(name: "Sunrise", colors: [.purple, .pink, .orange, .yellow])
    static let monochrome = GradientPreset(name: "Monochrome", colors: [.black, .gray, .white])

    // MARK: - All Presets (20 total)
    static let presets = [
        // Original
        ocean, sunset, forest, fire, midnight,
        // Warm
        peach, coral, amber, rose, honey,
        // Cool
        arctic, mint, lavender, sky, oceanic,
        // Special
        aurora, galaxy, candy, sunrise, monochrome
    ]
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

// MARK: - Annotation Models

struct Annotation: Identifiable, Codable {
    let id: UUID
    var type: AnnotationType
    var text: String
    var position: CGPoint
    var fontSize: Double
    var color: CodableColor
    var width: Double // For shapes
}

enum AnnotationType: String, Codable {
    case text
    case arrow
    case rectangle
    case ellipse
    case highlight
}

// Helper for Codable Color
struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    
    init(color: Color) {
        // Simplified - in production would extract actual RGB values
        self.red = 1.0
        self.green = 1.0
        self.blue = 1.0
        self.alpha = 1.0
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
