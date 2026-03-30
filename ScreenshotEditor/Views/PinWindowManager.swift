//
//  PinWindowManager.swift
//  ScreenshotEditor
//
//  Singleton manager for all pinned screenshot windows
//

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

    // MARK: - Persistence

    /// Save current workspace (pins and groups)
    func saveWorkspace(name: String = "Default") {
        let workspaceData: [String: Any] = [
            "name": name,
            "pins": activePins.keys.map { $0.uuidString },
            "groups": pinGroups.mapValues { $0.map { $0.uuidString } }
        ]

        // TODO: Implement actual persistence to ~/Documents/ScreenshotEditor/workspaces/
        #if DEBUG
        print("[PinWindowManager] Saving workspace: \(workspaceData)")
        #endif
    }

    /// Load a workspace
    func loadWorkspace(name: String) -> Bool {
        // TODO: Implement actual workspace loading
        #if DEBUG
        print("[PinWindowManager] Loading workspace: \(name)")
        #endif
        return false // Not yet implemented
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
