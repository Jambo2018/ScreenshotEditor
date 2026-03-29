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

    func exportCurrent(format: ImageFormat = .png, saveLocation: URL? = nil) {
        guard let screenshot = selectedScreenshot,
              let image = screenshot.image else {
            errorMessage = "No screenshot selected"
            return
        }

        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // Export image with current settings
                let data = try ImageExporter.exportImage(
                    sourceImage: image,
                    backgroundType: self?.backgroundType ?? .gradient,
                    gradient: self?.selectedGradient ?? .ocean,
                    solidColor: self?.selectedColor ?? .white,
                    blurAmount: self?.blurAmount ?? 0,
                    padding: self?.padding ?? 40,
                    cornerRadius: self?.cornerRadius ?? 12,
                    showShadow: self?.showShadow ?? true,
                    showBorder: self?.showBorder ?? false,
                    format: format
                )

                DispatchQueue.main.async {
                    self?.isExporting = false

                    if let saveLocation = saveLocation {
                        // Save to specific location
                        self?.saveToLocation(saveLocation, data: data)
                    } else {
                        // Show save panel
                        self?.showSavePanel(data: data, format: format)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isExporting = false
                    self?.errorMessage = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func saveToLocation(_ url: URL, data: Data) {
        do {
            try data.write(to: url)
            // Copy to clipboard
            copyToClipboard(data: data)
            showSuccessMessage("Saved and copied to clipboard")
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func showSavePanel(data: Data, format: ImageFormat) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = "Screenshot-\(Date().formatted(.dateTime.year().month().day().hour().minute()))\(format.fileExtension)"
        panel.canCreateDirectories = true
        panel.showsTagField = false

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.saveToLocation(url, data: data)
        }
    }

    private func copyToClipboard(data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    private func showSuccessMessage(_ message: String) {
        // Simple toast notification using errorMessage temporarily
        errorMessage = nil
        // In a real app, use a proper toast library or custom view
        print("Success: \(message)")
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
