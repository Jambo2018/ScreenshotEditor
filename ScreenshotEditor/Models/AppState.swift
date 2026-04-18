//
//  AppState.swift
//  ScreenshotEditor
//
//  Main app state manager using ObservableObject pattern
//

import SwiftUI
import UniformTypeIdentifiers
import CoreImage
import Combine

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class EditorDocumentState: ObservableObject {
    @Published var screenshots: [Screenshot] = []
    @Published var selectedScreenshotId: UUID?
    @Published var selectedScreenshotIds: Set<UUID> = []
    @Published var annotations: [Annotation] = []
    @Published var selectedAnnotationId: UUID?
    @Published var isAddingText = false
    @Published var currentTextColor: Color = .white
    @Published var currentTextSize: Double = 24
    @Published var selectedAnnotationTool: AnnotationTool = .select
    @Published var currentShapeColor: Color = .red
    @Published var currentStrokeWidth: Double = 2
    @Published var currentBrushSize: Double = 20
    @Published var currentBrushOpacity: Double = 0.5
}

final class CanvasStyleState: ObservableObject {
    @Published var backgroundType: BackgroundType = .color
    @Published var selectedGradient: GradientPreset = .cool
    @Published var useCustomGradient = false
    @Published var customGradientStartColor: Color = .blue
    @Published var customGradientEndColor: Color = .mint
    @Published var useSecondCustomGradientColor = false
    @Published var backgroundImage: PlatformImage?
    @Published var blurAmount: Double = 0
    @Published var padding: Double = 40
    @Published var cornerRadius: Double = 12
    @Published var showShadow = false
    @Published var showBorder = false
    @Published var deviceFrame: DeviceFrame = .none
    @Published var exportAspectRatio: ExportAspectRatio = .original
    @Published var customAspectRatioWidth: Double = 4
    @Published var customAspectRatioHeight: Double = 5
}

final class ExportWorkflowState: ObservableObject {
    @Published var isExporting = false
    @Published var isBatchExporting = false
    @Published var autoCopyToClipboard = true
    @Published var shareSheetFile: ShareSheetFile?
}

final class ImportCaptureState: ObservableObject {
    @Published var isCapturing = false
    @Published var isImportPickerPresented = false
    @Published var isBackgroundImagePickerPresented = false
    @Published var isPhotoPickerPresented = false
    @Published var isCaptureGuidePresented = false
}

final class EditorShellState: ObservableObject {
    @Published var errorMessage: String?
    @Published var isAnnotationPanelVisible = true
    @Published var isColorPickingMode = false
}

class AppState: ObservableObject {
    // MARK: - Published Properties

    let objectWillChange = ObservableObjectPublisher()

    let document = EditorDocumentState()
    let canvas = CanvasStyleState()
    let export = ExportWorkflowState()
    let intake = ImportCaptureState()
    let shell = EditorShellState()
    private var cancellables = Set<AnyCancellable>()

    // Screen capture
    #if os(macOS)
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var captureOverlayWindow: CaptureOverlayWindow?
    #endif

    // MARK: - Computed Properties

    var selectedScreenshot: Screenshot? {
        screenshots.first { $0.id == selectedScreenshotId }
    }

    var hasScreenshot: Bool {
        selectedScreenshot != nil
    }

    var activeGradientColors: [Color] {
        if useCustomGradient {
            return useSecondCustomGradientColor ? [customGradientStartColor, customGradientEndColor] : [customGradientStartColor]
        }
        return selectedGradient.colors
    }

    var resolvedAspectRatioValue: CGFloat? {
        switch exportAspectRatio {
        case .original:
            return nil
        case .square:
            return 1
        case .portrait34:
            return 3.0 / 4.0
        case .landscape43:
            return 4.0 / 3.0
        case .portrait916:
            return 9.0 / 16.0
        case .landscape169:
            return 16.0 / 9.0
        case .custom:
            guard customAspectRatioWidth > 0, customAspectRatioHeight > 0 else { return nil }
            return customAspectRatioWidth / customAspectRatioHeight
        }
    }

    var screenshots: [Screenshot] {
        get { document.screenshots }
        set { document.screenshots = newValue }
    }

    var selectedScreenshotId: UUID? {
        get { document.selectedScreenshotId }
        set { document.selectedScreenshotId = newValue }
    }

    var selectedScreenshotIds: Set<UUID> {
        get { document.selectedScreenshotIds }
        set { document.selectedScreenshotIds = newValue }
    }

    var annotations: [Annotation] {
        get { document.annotations }
        set { document.annotations = newValue }
    }

    var selectedAnnotationId: UUID? {
        get { document.selectedAnnotationId }
        set { document.selectedAnnotationId = newValue }
    }

    var isAddingText: Bool {
        get { document.isAddingText }
        set { document.isAddingText = newValue }
    }

    var currentTextColor: Color {
        get { document.currentTextColor }
        set { document.currentTextColor = newValue }
    }

    var currentTextSize: Double {
        get { document.currentTextSize }
        set { document.currentTextSize = newValue }
    }

    var selectedAnnotationTool: AnnotationTool {
        get { document.selectedAnnotationTool }
        set { document.selectedAnnotationTool = newValue }
    }

    var currentShapeColor: Color {
        get { document.currentShapeColor }
        set { document.currentShapeColor = newValue }
    }

    var currentStrokeWidth: Double {
        get { document.currentStrokeWidth }
        set { document.currentStrokeWidth = newValue }
    }

    var currentBrushSize: Double {
        get { document.currentBrushSize }
        set { document.currentBrushSize = newValue }
    }

    var currentBrushOpacity: Double {
        get { document.currentBrushOpacity }
        set { document.currentBrushOpacity = newValue }
    }

    var backgroundType: BackgroundType {
        get { canvas.backgroundType }
        set { canvas.backgroundType = newValue }
    }

    var selectedGradient: GradientPreset {
        get { canvas.selectedGradient }
        set { canvas.selectedGradient = newValue }
    }

    var useCustomGradient: Bool {
        get { canvas.useCustomGradient }
        set { canvas.useCustomGradient = newValue }
    }

    var customGradientStartColor: Color {
        get { canvas.customGradientStartColor }
        set { canvas.customGradientStartColor = newValue }
    }

    var customGradientEndColor: Color {
        get { canvas.customGradientEndColor }
        set { canvas.customGradientEndColor = newValue }
    }

    var useSecondCustomGradientColor: Bool {
        get { canvas.useSecondCustomGradientColor }
        set { canvas.useSecondCustomGradientColor = newValue }
    }

    var backgroundImage: PlatformImage? {
        get { canvas.backgroundImage }
        set { canvas.backgroundImage = newValue }
    }

    var blurAmount: Double {
        get { canvas.blurAmount }
        set { canvas.blurAmount = newValue }
    }

    var padding: Double {
        get { canvas.padding }
        set { canvas.padding = newValue }
    }

    var cornerRadius: Double {
        get { canvas.cornerRadius }
        set { canvas.cornerRadius = newValue }
    }

    var showShadow: Bool {
        get { canvas.showShadow }
        set { canvas.showShadow = newValue }
    }

    var showBorder: Bool {
        get { canvas.showBorder }
        set { canvas.showBorder = newValue }
    }

    var deviceFrame: DeviceFrame {
        get { canvas.deviceFrame }
        set { canvas.deviceFrame = newValue }
    }

    var exportAspectRatio: ExportAspectRatio {
        get { canvas.exportAspectRatio }
        set { canvas.exportAspectRatio = newValue }
    }

    var customAspectRatioWidth: Double {
        get { canvas.customAspectRatioWidth }
        set { canvas.customAspectRatioWidth = newValue }
    }

    var customAspectRatioHeight: Double {
        get { canvas.customAspectRatioHeight }
        set { canvas.customAspectRatioHeight = newValue }
    }

    var isExporting: Bool {
        get { export.isExporting }
        set { export.isExporting = newValue }
    }

    var isBatchExporting: Bool {
        get { export.isBatchExporting }
        set { export.isBatchExporting = newValue }
    }

    var autoCopyToClipboard: Bool {
        get { export.autoCopyToClipboard }
        set { export.autoCopyToClipboard = newValue }
    }

    var shareSheetFile: ShareSheetFile? {
        get { export.shareSheetFile }
        set { export.shareSheetFile = newValue }
    }

    var isCapturing: Bool {
        get { intake.isCapturing }
        set { intake.isCapturing = newValue }
    }

    var isImportPickerPresented: Bool {
        get { intake.isImportPickerPresented }
        set { intake.isImportPickerPresented = newValue }
    }

    var isBackgroundImagePickerPresented: Bool {
        get { intake.isBackgroundImagePickerPresented }
        set { intake.isBackgroundImagePickerPresented = newValue }
    }

    var isPhotoPickerPresented: Bool {
        get { intake.isPhotoPickerPresented }
        set { intake.isPhotoPickerPresented = newValue }
    }

    var isCaptureGuidePresented: Bool {
        get { intake.isCaptureGuidePresented }
        set { intake.isCaptureGuidePresented = newValue }
    }

    var errorMessage: String? {
        get { shell.errorMessage }
        set { shell.errorMessage = newValue }
    }

    var isAnnotationPanelVisible: Bool {
        get { shell.isAnnotationPanelVisible }
        set { shell.isAnnotationPanelVisible = newValue }
    }

    var isColorPickingMode: Bool {
        get { shell.isColorPickingMode }
        set { shell.isColorPickingMode = newValue }
    }

    // MARK: - Initialization

    init() {
        bindChildState()
        loadFromiCloud()
        setupHotKey()
    }

    private func bindChildState() {
        document.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        canvas.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        export.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        intake.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        shell.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Screen Capture Setup

    private func setupHotKey() {
        #if os(macOS)
        // Check accessibility permission
        if !GlobalHotKeyMonitor.hasAccessibilityPermission() {
            #if DEBUG
            print("[HotKey] WARNING: Accessibility permission not granted!")
            #endif
        }

        hotKeyMonitor = GlobalHotKeyMonitor()

        // Cmd+Shift+K: Start screen capture
        hotKeyMonitor?.register(
            key: .k,
            modifiers: [.command, .shift]
        ) { [weak self] in
            self?.startScreenCapture()
        }

        // F3: Pin current screenshot (Snipaste-style)
        hotKeyMonitor?.register(
            key: .f3,
            modifiers: []
        ) { [weak self] in
            self?.pinCurrentScreenshot()
        }

        // Shift+F3: Close all pin windows
        hotKeyMonitor?.register(
            key: .f3,
            modifiers: [.shift]
        ) { [weak self] in
            self?.closeAllPinWindows()
        }
        #endif

    }

    func startScreenCapture() {
        #if os(macOS)
        // Prevent multiple captures
        if isCapturing {
            #if DEBUG
            print("[Capture] Already capturing, ignoring")
            #endif
            return
        }

        #if DEBUG
        print("[Capture] Starting screen capture...")
        #endif

        // Request permission if needed
        Task { @MainActor in
            if !ScreenCapturer.hasScreenRecordingPermission() {
                #if DEBUG
                print("[Capture] Requesting permission...")
                #endif
                let granted = await ScreenCapturer.requestPermission()
                if !granted {
                    #if DEBUG
                    print("[Capture] Permission denied")
                    #endif
                    self.errorMessage = "Screen recording permission denied"
                    self.isCapturing = false
                    return
                }
            }

            self.isCapturing = true

            // Setup shared overlay window
            let overlay = CaptureOverlayWindow.shared
            self.captureOverlayWindow = overlay

            // Capture overlay callbacks
            overlay.onCaptureConfirmed = { [weak self] rect in
                #if DEBUG
                print("[Capture] Capture confirmed, rect: \(rect)")
                #endif

                guard let self = self else { return }

                // Reset state
                self.captureOverlayWindow = nil
                self.isCapturing = false

                // Capture on background thread
                self.captureRegion(rect)
            }

            overlay.onCaptureCancelled = { [weak self] in
                #if DEBUG
                print("[Capture] Capture cancelled")
                #endif

                guard let self = self else { return }

                // Reset state
                self.captureOverlayWindow = nil
                self.isCapturing = false
            }

            // Show the overlay
            overlay.show()

            // Timeout safety: force close after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self else { return }

                #if DEBUG
                print("[Capture] Timeout triggered")
                #endif

                // Hide the overlay window
                self.captureOverlayWindow?.hide()
                self.captureOverlayWindow = nil
                self.isCapturing = false
            }
        }
        #else
        errorMessage = "Screen capture is not available on this platform yet"
        #endif
    }

    // MARK: - Screen Capture

    private func captureRegion(_ rect: CGRect) {
        #if os(macOS)
        // Capture on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let image = ScreenCapturer.captureRegion(rect) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to capture screen"
                }
                return
            }

            let capturedImage = PlatformImage.from(cgImage: image)

            let screenshot = Screenshot(
                id: UUID(),
                name: "Screenshot-\(Date().formatted(.dateTime.hour().minute().second()))",
                sourceURL: nil,
                createdAt: Date(),
                image: capturedImage
            )

            // Update UI on main thread
            DispatchQueue.main.async {
                self.setCurrentScreenshot(screenshot)
            }
        }
        #endif
    }

    // MARK: - Actions

    var canCaptureScreen: Bool {
        #if os(macOS)
        true
        #else
        true
        #endif
    }

    func requestScreenCapture() {
        #if os(macOS)
        startScreenCapture()
        #else
        isCaptureGuidePresented = true
        #endif
    }

    func requestPhotoImport() {
        #if os(iOS)
        isPhotoPickerPresented = true
        #else
        requestImageImport()
        #endif
    }

    func requestImageImport() {
        #if os(macOS)
        importScreenshot()
        #else
        isImportPickerPresented = true
        #endif
    }

    func requestBackgroundImageImport() {
        #if os(macOS)
        importBackgroundImage()
        #else
        isBackgroundImagePickerPresented = true
        #endif
    }

    func importScreenshot() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a screenshot to edit"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.loadImage(from: url)
        }
        #endif
    }

    func importBackgroundImage() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select background image"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.loadBackgroundImage(from: url)
        }
        #endif
    }

    func loadImage(from url: URL) {
        let isScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if isScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let image = PlatformImage.load(contentsOf: url) else {
            errorMessage = "Failed to load image"
            return
        }

        replaceCurrentImage(image, name: url.lastPathComponent, sourceURL: url)
    }

    func loadBackgroundImage(from url: URL) {
        let isScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if isScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let image = PlatformImage.load(contentsOf: url) else {
            errorMessage = "Failed to load background image"
            return
        }

        withAnimation {
            backgroundType = .image
            backgroundImage = normalizedImageForEditing(image)
            useCustomGradient = false
        }
    }

    func replaceCurrentImage(_ image: PlatformImage, name: String, sourceURL: URL? = nil) {
        let normalized = normalizedImageForEditing(image)

        let screenshot = Screenshot(
            id: UUID(),
            name: name,
            sourceURL: sourceURL,
            createdAt: Date(),
            image: normalized
        )

        DispatchQueue.main.async {
            self.setCurrentScreenshot(screenshot)
        }
    }

    private func normalizedImageForEditing(_ image: PlatformImage) -> PlatformImage {
        guard let cgImage = image.cgImageValue else {
            return image
        }
        return PlatformImage.from(cgImage: cgImage)
    }

    func setCurrentScreenshot(_ screenshot: Screenshot) {
        screenshots = [screenshot]
        selectedScreenshotId = screenshot.id
        selectedScreenshotIds = [screenshot.id]
        annotations.removeAll()
        selectedAnnotationId = nil
    }

    func exportCurrent(format: ImageFormat = .png, copyToClipboard: Bool? = nil) {
        guard let screenshot = selectedScreenshot,
              let image = screenshot.image else {
            errorMessage = "No screenshot selected"
            print("[Export] ERROR: No screenshot or image available")
            return
        }

        print("[Export] Starting export from AppState")
        print("[Export] Background: \(backgroundType.rawValue), Gradient: \(selectedGradient.name)")
        print("[Export] Settings: blur=\(blurAmount), padding=\(padding), corner=\(cornerRadius)")

        isExporting = true

        exportImages(images: [(image, screenshot.name)], format: format, copyToClipboard: copyToClipboard)
    }

    func shareCurrent(format: ImageFormat = .png, from anchorView: PlatformView? = nil) {
        guard let screenshot = selectedScreenshot,
              let image = screenshot.image else {
            errorMessage = "No screenshot selected"
            return
        }

        isExporting = true

        let shareName = screenshot.name.isEmpty ? "Screenshot" : screenshot.name

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try self.renderedImageData(
                    sourceImage: image,
                    format: format
                )
                let fileURL = try self.writeTemporaryShareFile(
                    data: data,
                    baseName: shareName,
                    format: format
                )

                DispatchQueue.main.async {
                    self.isExporting = false
                    self.presentShareSheet(for: fileURL, from: anchorView)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.errorMessage = "Share failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func exportBatch(format: ImageFormat = .png, copyToClipboard: Bool = false) {
        guard !selectedScreenshotIds.isEmpty else {
            errorMessage = "No screenshots selected for batch export"
            return
        }
        
        isBatchExporting = true
        
        var imagesToExport: [(PlatformImage, String)] = []
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
    
    private func exportImages(images: [(PlatformImage, String)], format: ImageFormat, copyToClipboard: Bool?) {
        let isBatch = images.count > 1
        
        if isBatch {
            isBatchExporting = true
        } else {
            isExporting = true
        }

        let currentBackgroundType = backgroundType
        let currentGradientColors = activeGradientColors
        let currentBlurAmount = blurAmount
        let currentPadding = padding
        let currentCornerRadius = cornerRadius
        let currentDeviceFrame = deviceFrame
        let currentAspectRatio = exportAspectRatio
        let currentCustomAspectRatio = CGSize(width: customAspectRatioWidth, height: customAspectRatioHeight)
        let shouldCopyToClipboard = copyToClipboard ?? autoCopyToClipboard

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("[Export] ERROR: Self is nil in async block")
                return
            }

            do {
                #if os(macOS)
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
                                    let data = try self.renderedImageData(
                                        sourceImage: image,
                                        format: format,
                                        backgroundType: currentBackgroundType,
                                        gradientColors: currentGradientColors,
                                        blurAmount: currentBlurAmount,
                                        padding: currentPadding,
                                        cornerRadius: currentCornerRadius,
                                        deviceFrame: currentDeviceFrame,
                                        aspectRatio: currentAspectRatio,
                                        customAspectRatio: currentCustomAspectRatio
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
                    let data = try self.renderedImageData(
                        sourceImage: images.first!.0,
                        format: format,
                        backgroundType: currentBackgroundType,
                        gradientColors: currentGradientColors,
                        blurAmount: currentBlurAmount,
                        padding: currentPadding,
                        cornerRadius: currentCornerRadius,
                        deviceFrame: currentDeviceFrame,
                        aspectRatio: currentAspectRatio,
                        customAspectRatio: currentCustomAspectRatio
                    )

                    print("[Export] Export succeeded, data size: \(data.count) bytes")

                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.isBatchExporting = false
                        self.showSavePanel(data: data, format: format, copyToClipboard: shouldCopyToClipboard)
                    }
                }
                #else
                let data = try self.renderedImageData(
                    sourceImage: images.first!.0,
                    format: format,
                    backgroundType: currentBackgroundType,
                    gradientColors: currentGradientColors,
                    blurAmount: currentBlurAmount,
                    padding: currentPadding,
                    cornerRadius: currentCornerRadius,
                    deviceFrame: currentDeviceFrame,
                    aspectRatio: currentAspectRatio,
                    customAspectRatio: currentCustomAspectRatio
                )

                DispatchQueue.main.async {
                    self.isExporting = false
                    self.isBatchExporting = false
                    self.showSavePanel(data: data, format: format, copyToClipboard: shouldCopyToClipboard)
                }
                #endif
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
        #if os(macOS)
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
        #else
        do {
            let fileURL = try writeTemporaryShareFile(
                data: data,
                baseName: "Screenshot-\(Date().formatted(.dateTime.year().month().day().hour().minute()))",
                format: format
            )

            if copyToClipboard {
                self.copyToClipboard(data: data)
            }

            self.shareSheetFile = ShareSheetFile(url: fileURL)
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to prepare export: \(error.localizedDescription)"
        }
        #endif
    }

    private func copyToClipboard(data: Data) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
        #else
        if let image = PlatformImage(data: data) {
            UIPasteboard.general.image = image
        }
        #endif
    }

    private func renderedImageData(
        sourceImage: PlatformImage,
        format: ImageFormat,
        backgroundType: BackgroundType? = nil,
        gradientColors: [Color]? = nil,
        blurAmount: Double? = nil,
        padding: Double? = nil,
        cornerRadius: Double? = nil,
        deviceFrame: DeviceFrame? = nil,
        aspectRatio: ExportAspectRatio? = nil,
        customAspectRatio: CGSize? = nil
    ) throws -> Data {
        try ImageExporter.exportImage(
            sourceImage: sourceImage,
            backgroundType: backgroundType ?? self.backgroundType,
            gradientColors: gradientColors ?? activeGradientColors,
            backgroundImage: backgroundImage,
            blurAmount: blurAmount ?? self.blurAmount,
            padding: padding ?? self.padding,
            cornerRadius: cornerRadius ?? self.cornerRadius,
            showShadow: false,
            showBorder: false,
            deviceFrame: deviceFrame ?? self.deviceFrame,
            aspectRatio: aspectRatio ?? exportAspectRatio,
            customAspectRatio: customAspectRatio ?? CGSize(width: customAspectRatioWidth, height: customAspectRatioHeight),
            annotations: annotations,
            format: format
        )
    }

    private func writeTemporaryShareFile(data: Data, baseName: String, format: ImageFormat) throws -> URL {
        let sanitizedName = baseName
            .replacingOccurrences(of: format.fileExtension, with: "")
            .replacingOccurrences(of: "/", with: "-")
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory
            .appendingPathComponent("\(sanitizedName)-share-\(UUID().uuidString)")
            .appendingPathExtension(String(format.fileExtension.dropFirst()))
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func presentShareSheet(for fileURL: URL, from anchorView: PlatformView?) {
        #if os(macOS)
        guard let sourceView = anchorView ?? NSApp.keyWindow?.contentView ?? NSApp.mainWindow?.contentView else {
            errorMessage = "Unable to open the share sheet"
            return
        }

        let picker = NSSharingServicePicker(items: [fileURL])
        picker.show(relativeTo: sourceView.bounds, of: sourceView, preferredEdge: .maxY)
        #else
        shareSheetFile = ShareSheetFile(url: fileURL)
        #endif
    }

    func deleteScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
        selectedScreenshotIds.remove(screenshot.id)
        if selectedScreenshotId == screenshot.id {
            selectedScreenshotId = screenshots.first?.id
        }
        if selectedScreenshotId == nil {
            annotations.removeAll()
            selectedAnnotationId = nil
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
              (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) != nil else {
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
                "useCustomGradient": useCustomGradient,
                "useSecondCustomGradientColor": useSecondCustomGradientColor,
                "blurAmount": blurAmount,
                "padding": padding,
                "cornerRadius": cornerRadius,
                "showShadow": showShadow,
                "showBorder": showBorder,
                "deviceFrame": deviceFrame.rawValue,
                "autoCopyToClipboard": autoCopyToClipboard,
                "exportAspectRatio": exportAspectRatio.rawValue,
                "customAspectRatioWidth": customAspectRatioWidth,
                "customAspectRatioHeight": customAspectRatioHeight
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
                  let pngData = image.pngRepresentation() else {
                continue
            }

            let imageFile = appFolder.appendingPathComponent("\(screenshot.id.uuidString).png")
            try? pngData.write(to: imageFile)
        }
    }

    private func saveTtoiCloud() {
        // Deprecated: Use saveToiCloud instead
        saveToiCloud()
    }

    // MARK: - Pin Window Management

    func pinCurrentScreenshot() {
        #if os(macOS)
        guard let screenshot = selectedScreenshot,
              let image = screenshot.image else {
            #if DEBUG
            print("[Pin] No screenshot selected")
            #endif
            return
        }

        #if DEBUG
        print("[Pin] Creating pin window for screenshot: \(screenshot.id)")
        #endif

        PinWindowManager.shared.createPin(image: image, position: nil, group: nil)
        #endif
    }

    func closeAllPinWindows() {
        #if os(macOS)
        #if DEBUG
        print("[Pin] Closing all pin windows")
        #endif
        PinWindowManager.shared.closeAllPins()
        #endif
    }

    // MARK: - Color Helper

    func pickColor(at screenPoint: CGPoint) -> Color? {
        #if os(macOS)
        guard let image = ScreenCapturer.captureScreen(at: screenPoint, size: CGSize(width: 1, height: 1)),
              let cgImage = image.cgImageValue,
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return nil
        }

        let data = CFDataGetBytePtr(pixelData)!
        let red = CGFloat(data[0]) / 255.0
        let green = CGFloat(data[1]) / 255.0
        let blue = CGFloat(data[2]) / 255.0

        return Color(red: red, green: green, blue: blue)
        #else
        return nil
        #endif
    }

    func setColorForCurrentTool(_ color: Color) {
        switch selectedAnnotationTool {
        case .text:
            currentTextColor = color
        case .rectangle, .arrow, .mosaic, .freehand:
            currentShapeColor = color
        default:
            break
        }
        #if DEBUG
        print("[ColorPicker] Set color for current tool")
        #endif
    }
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

struct ShareSheetFile: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Supporting Types

enum BackgroundType: String, CaseIterable {
    case color = "Color"
    case none = "None"
    case image = "Image"
}

struct GradientPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let colors: [Color]

    static let desktop = GradientPreset(name: "Desktop", colors: [Color(red: 0.16, green: 0.52, blue: 0.84), Color(red: 0.38, green: 0.72, blue: 0.73)])
    static let cool = GradientPreset(name: "Cool", colors: [Color(red: 0.20, green: 0.59, blue: 0.85), Color(red: 0.40, green: 0.74, blue: 0.75)])
    static let beach = GradientPreset(name: "Beach", colors: [Color(red: 0.09, green: 0.71, blue: 0.73), Color(red: 0.10, green: 0.75, blue: 0.57)])
    static let violet = GradientPreset(name: "Violet", colors: [Color(red: 0.32, green: 0.42, blue: 0.85), Color(red: 0.49, green: 0.33, blue: 0.86)])
    static let rose = GradientPreset(name: "Rose", colors: [Color(red: 0.99, green: 0.61, blue: 0.43), Color(red: 0.59, green: 0.78, blue: 0.89)])
    static let love = GradientPreset(name: "Love", colors: [Color(red: 0.47, green: 0.14, blue: 0.77), Color(red: 0.96, green: 0.26, blue: 0.69)])
    static let flower = GradientPreset(name: "Flower", colors: [Color(red: 0.66, green: 0.73, blue: 0.97), Color(red: 0.90, green: 0.70, blue: 0.94)])
    static let sky = GradientPreset(name: "Sky", colors: [Color(red: 0.40, green: 0.74, blue: 0.95), Color(red: 0.55, green: 0.90, blue: 0.88)])

    static let presets = [
        desktop, cool, beach, violet, rose,
        love, flower, sky
    ]
}

enum DeviceFrame: String, CaseIterable {
    case none = "None"
    case iphone = "iPhone"
    case macbook = "MacBook"
}

enum ExportAspectRatio: String, CaseIterable {
    case original = "Original"
    case square = "1:1"
    case portrait34 = "3:4"
    case landscape43 = "4:3"
    case portrait916 = "9:16"
    case landscape169 = "16:9"
    case custom = "Custom"
}

// MARK: - Annotation Models

struct Annotation: Identifiable, Codable {
    let id: UUID
    var type: AnnotationType
    var text: String
    var position: CGPoint
    var fontSize: Double
    var color: CodableColor
    var width: Double
    var startPoint: CGPoint?
    var endPoint: CGPoint?
    var size: CGSize?
    var points: [CGPoint]?
}

enum AnnotationType: String, Codable {
    case text
    case arrow
    case rectangle
    case ellipse
    case highlight
    case blur
    case mosaic
    case number
    case freehand
}

enum AnnotationTool: String, CaseIterable {
    case select = "select"
    case text = "text"
    case arrow = "arrow"
    case rectangle = "rectangle"
    case mosaic = "mosaic"
    case freehand = "freehand"

    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .text: return "textformat"
        case .arrow: return "arrow.right"
        case .rectangle: return "rectangle"
        case .mosaic: return "pixel"
        case .freehand: return "pencil"
        }
    }

    var title: String {
        switch self {
        case .select: return "选择"
        case .text: return "文字"
        case .arrow: return "箭头"
        case .rectangle: return "矩形"
        case .mosaic: return "马赛克"
        case .freehand: return "自由绘"
        }
    }
}

extension AnnotationType {
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .arrow: return "arrow.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .highlight: return "marker"
        case .blur: return "blur"
        case .mosaic: return "pixel"
        case .number: return "number"
        case .freehand: return "pencil"
        }
    }
}

extension Annotation {
    var displayName: String {
        switch type {
        case .text:
            return text.isEmpty ? "文字" : text
        case .arrow: return "箭头"
        case .rectangle: return "矩形"
        case .ellipse: return "椭圆"
        case .highlight: return "高亮"
        case .blur: return "模糊"
        case .mosaic: return "马赛克"
        case .number: return "编号"
        case .freehand: return "自由绘"
        }
    }
}

struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(color: Color) {
        if color == .white {
            self.red = 1.0; self.green = 1.0; self.blue = 1.0; self.alpha = 1.0
        } else if color == .black {
            self.red = 0.0; self.green = 0.0; self.blue = 0.0; self.alpha = 1.0
        } else if color == .red {
            self.red = 1.0; self.green = 0.0; self.blue = 0.0; self.alpha = 1.0
        } else if color == .green {
            self.red = 0.0; self.green = 1.0; self.blue = 0.0; self.alpha = 1.0
        } else if color == .blue {
            self.red = 0.0; self.green = 0.0; self.blue = 1.0; self.alpha = 1.0
        } else if color == .yellow {
            self.red = 1.0; self.green = 1.0; self.blue = 0.0; self.alpha = 1.0
        } else {
            self.red = 1.0; self.green = 1.0; self.blue = 1.0; self.alpha = 1.0
        }
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
