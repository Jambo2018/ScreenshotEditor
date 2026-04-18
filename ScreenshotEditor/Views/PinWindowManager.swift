//
//  PinWindowManager.swift
//  ScreenshotEditor
//
//  Singleton manager for all pinned screenshot windows
//

#if os(macOS)
import AppKit
import Foundation

/// Manages all active pinned windows
/// - Singleton pattern (similar to CaptureOverlayWindow.shared)
/// - Tracks active pins, handles creation and cleanup
class PinWindowManager {

    // MARK: - Singleton

    static let shared = PinWindowManager()

    private init() {
        #if DEBUG
        print("[PinWindowManager] Initialized singleton")
        #endif
    }

    // MARK: - Properties

    @Published private(set) var activePins: [UUID: PinWindow] = [:]
    @Published private(set) var pinGroups: [String: [UUID]] = [:]

    // Vision Framework availability (static check)
    private(set) var isVisionAvailable: Bool = true

    // MARK: - Pin Management

    /// Create a new pin window
    /// - Parameters:
    ///   - image: The screenshot image to display
    ///   - position: Initial window position (default: center of main screen)
    ///   - group: Optional group name for organizing pins
    /// - Returns: The created pin's UUID, or nil if creation failed
    @discardableResult
    func createPin(
        image: NSImage,
        position: CGPoint? = nil,
        group: String? = nil
    ) -> UUID? {
        guard let screen = NSScreen.main else {
            #if DEBUG
            print("[PinWindowManager] ERROR: No screen available")
            #endif
            return nil
        }

        // Determine position
        let pinPosition = position ?? CGPoint(
            x: screen.frame.midX - 400,
            y: screen.frame.midY - 300
        )

        // Create pin
        let pinId = UUID()
        let pin = PinWindow(
            id: pinId,
            image: image,
            position: pinPosition
        )

        // Set closure for cleanup
        pin.onClose = { [weak self] id in
            self?.handlePinClosed(id)
        }

        // Track pin
        activePins[pinId] = pin

        // Add to group if specified
        if let group = group {
            addToGroup(group, pinId: pinId)
        }

        #if DEBUG
        print("[PinWindowManager] Created pin \(pinId) at \(pinPosition)")
        #endif

        return pinId
    }

    /// Close a specific pin
    func closePin(id: UUID) {
        guard let pin = activePins[id] else {
            #if DEBUG
            print("[PinWindowManager] Pin \(id) not found")
            #endif
            return
        }

        pin.closeWindow()
    }

    /// Close all pins
    func closeAllPins() {
        let ids = Array(activePins.keys)
        for id in ids {
            closePin(id: id)
        }
    }

    /// Close all pins except the specified one
    func closeOtherPins(except id: UUID) {
        let ids = activePins.keys.filter { $0 != id }
        for id in ids {
            closePin(id: id)
        }
    }

    /// Handle pin closure (called by PinWindow)
    private func handlePinClosed(_ id: UUID) {
        activePins.removeValue(forKey: id)

        // Remove from all groups
        for (group, pins) in pinGroups {
            if let index = pins.firstIndex(of: id) {
                pinGroups[group]?.remove(at: index)
            }
        }

        // Clean up empty groups
        pinGroups = pinGroups.filter { !$0.value.isEmpty }

        #if DEBUG
        print("[PinWindowManager] Pin \(id) closed, \(activePins.count) remaining")
        #endif
    }

    // MARK: - Group Management

    /// Add a pin to a group
    func addToGroup(_ groupName: String, pinId: UUID) {
        if pinGroups[groupName] == nil {
            pinGroups[groupName] = []
        }

        if var pins = pinGroups[groupName] {
            if !pins.contains(pinId) {
                pins.append(pinId)
                pinGroups[groupName] = pins
            }
        }
    }

    /// Remove a pin from a group
    func removeFromGroup(_ groupName: String, pinId: UUID) {
        guard var pins = pinGroups[groupName] else { return }

        pins.removeAll { $0 == pinId }
        pinGroups[groupName] = pins.isEmpty ? nil : pins
    }

    /// Get all pins in a group
    func pinsInGroup(_ groupName: String) -> [UUID] {
        return pinGroups[groupName] ?? []
    }

    /// Hide all pins in a group
    func hideGroup(_ groupName: String) {
        let pins = pinsInGroup(groupName)
        for pinId in pins {
            activePins[pinId]?.alphaValue = 0.0
        }
    }

    /// Show all pins in a group
    func showGroup(_ groupName: String) {
        let pins = pinsInGroup(groupName)
        for pinId in pins {
            activePins[pinId]?.alphaValue = 1.0
        }
    }

    /// Toggle group visibility
    func toggleGroup(_ groupName: String) {
        let pins = pinsInGroup(groupName)
        guard let firstPin = pins.first,
              let pin = activePins[firstPin] else { return }

        if pin.alphaValue > 0.5 {
            hideGroup(groupName)
        } else {
            showGroup(groupName)
        }
    }

    // MARK: - Vision Framework Check

    /// Check if Vision Framework is available (macOS 13+)
    func checkVisionAvailability() {
        if #available(macOS 13.0, *) {
            isVisionAvailable = true
        } else {
            isVisionAvailable = false
        }

        #if DEBUG
        print("[PinWindowManager] Vision available: \(isVisionAvailable)")
        #endif
    }


    #if DEBUG
    func resetForTesting() {
        for pin in activePins.values {
            pin.onClose = nil
            pin.orderOut(nil)
            pin.contentView = nil
        }
        activePins.removeAll()
        pinGroups.removeAll()
    }
    #endif

    // MARK: - Persistence

    /// Save current workspace (pins and groups)
    func saveWorkspace(name: String = "Default") {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            print("[Workspace] ERROR: Could not access documents directory")
            #endif
            return
        }

        let appFolder = documentsPath.appendingPathComponent("ScreenshotEditor", isDirectory: true)
        let workspacesFolder = appFolder.appendingPathComponent("workspaces", isDirectory: true)

        // Create folders if they don't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: workspacesFolder, withIntermediateDirectories: true)

        // Build workspace data with pin details
        var pinsData: [[String: Any]] = []
        for (pinId, pinWindow) in activePins {
            var pinData: [String: Any] = [
                "id": pinId.uuidString,
                "frame": [
                    "x": pinWindow.frame.origin.x,
                    "y": pinWindow.frame.origin.y,
                    "width": pinWindow.frame.size.width,
                    "height": pinWindow.frame.size.height
                ],
                "opacity": pinWindow.opacityValue,
                "scaleFactor": pinWindow.scaleFactor,
                "rotationAngle": pinWindow.rotationAngle
            ]

            // Save pin image
            if let imageView = pinWindow.contentView?.subviews.compactMap({ $0 as? NSImageView }).first,
               let image = imageView.image,
               let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil as [NSImageRep.HintKey: Any]?) {
                let imageFile = workspacesFolder.appendingPathComponent("\(name)_\(pinId.uuidString).png")
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                if let pngData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
                    try? pngData.write(to: imageFile)
                    pinData["imageFile"] = "\(name)_\(pinId.uuidString).png"
                }
            }

            pinsData.append(pinData)
        }

        let workspaceData: [String: Any] = [
            "name": name,
            "savedAt": ISO8601DateFormatter().string(from: Date()),
            "pins": pinsData,
            "groups": pinGroups.mapValues { $0.map { $0.uuidString } }
        ]

        let workspaceFile = workspacesFolder.appendingPathComponent("\(name).json")
        if let data = try? JSONSerialization.data(withJSONObject: workspaceData, options: .prettyPrinted) {
            try? data.write(to: workspaceFile)
            #if DEBUG
            print("[Workspace] Saved workspace: \(name)")
            #endif
        }
    }

    /// Load a workspace
    func loadWorkspace(name: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            print("[Workspace] ERROR: Could not access documents directory")
            #endif
            return false
        }

        let workspacesFolder = documentsPath
            .appendingPathComponent("ScreenshotEditor", isDirectory: true)
            .appendingPathComponent("workspaces", isDirectory: true)

        let workspaceFile = workspacesFolder.appendingPathComponent("\(name).json")

        guard FileManager.default.fileExists(atPath: workspaceFile.path),
              let data = try? Data(contentsOf: workspaceFile),
              let workspace = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            #if DEBUG
            print("[Workspace] Workspace not found: \(name)")
            #endif
            return false
        }

        // Close existing pins
        closeAllPins()

        // Load pins
        guard let pinsData = workspace["pins"] as? [[String: Any]] else {
            return false
        }

        for pinData in pinsData {
            guard let idString = pinData["id"] as? String,
                  let _ = UUID(uuidString: idString),
                  let imageFile = pinData["imageFile"] as? String else {
                continue
            }

            let imageFilePath = workspacesFolder.appendingPathComponent(imageFile)
            guard let image = NSImage(contentsOf: imageFilePath) else {
                continue
            }

            // Get position from saved frame
            var position = CGPoint(x: 100, y: 100)
            if let frame = pinData["frame"] as? [String: Double] {
                position = CGPoint(x: frame["x"] ?? 100, y: frame["y"] ?? 100)
            }

            // Create pin
            createPin(image: image, position: position, group: nil)
        }

        // Load groups
        if let groups = workspace["groups"] as? [String: [String]] {
            for (groupName, pinIds) in groups {
                for idString in pinIds {
                    if let pinId = UUID(uuidString: idString) {
                        addToGroup(groupName, pinId: pinId)
                    }
                }
            }
        }

        #if DEBUG
        print("[Workspace] Loaded workspace: \(name)")
        #endif

        return true
    }

    /// List available workspaces
    func listWorkspaces() -> [String] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        let workspacesFolder = documentsPath
            .appendingPathComponent("ScreenshotEditor", isDirectory: true)
            .appendingPathComponent("workspaces", isDirectory: true)

        guard let files = try? FileManager.default.contentsOfDirectory(atPath: workspacesFolder.path) else {
            return []
        }

        return files
            .filter { $0.hasSuffix(".json") }
            .map { String($0.dropLast(5)) } // Remove .json extension
    }

    /// Delete a workspace
    func deleteWorkspace(name: String) -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        let workspacesFolder = documentsPath
            .appendingPathComponent("ScreenshotEditor", isDirectory: true)
            .appendingPathComponent("workspaces", isDirectory: true)

        let workspaceFile = workspacesFolder.appendingPathComponent("\(name).json")

        do {
            try FileManager.default.removeItem(at: workspaceFile)

            // Also delete associated pin images
            if let files = try? FileManager.default.contentsOfDirectory(atPath: workspacesFolder.path) {
                for file in files where file.hasPrefix("\(name)_") && file.hasSuffix(".png") {
                    let imageFile = workspacesFolder.appendingPathComponent(file)
                    try? FileManager.default.removeItem(at: imageFile)
                }
            }

            return true
        } catch {
            #if DEBUG
            print("[Workspace] Failed to delete workspace: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Statistics

    var activePinCount: Int {
        return activePins.count
    }

    var groupCount: Int {
        return pinGroups.count
    }
}

// MARK: - Vision Framework Availability Check (macOS 13+)

@available(macOS 13.0, *)
extension PinWindowManager {
    /// Check if Vision Framework can be used for annotation suggestions
    static var isVisionSupported: Bool {
        // Additional runtime checks can be added here
        return true
    }
}
#endif
