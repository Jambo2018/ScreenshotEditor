//
//  GlobalHotKey.swift
//  ScreenshotEditor
//
//  Global hotkey monitoring for screen capture trigger
//

import AppKit
import Carbon.HIToolbox

class GlobalHotKeyMonitor {

    private var eventMonitor: EventMonitor?
    private var isRegistered = false
    private var handler: (() -> Void)?

    /// Check if accessibility permissions are granted
    static func hasAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Request accessibility permission
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Register a global hotkey handler
    /// - Parameters:
    ///   - key: The key equivalent (e.g., .k for "K")
    ///   - modifiers: Modifier flags (e.g., [.command, .shift])
    ///   - handler: Closure to execute when hotkey is pressed
    func register(
        key: KeyEquivalent,
        modifiers: NSEvent.ModifierFlags,
        handler: @escaping () -> Void
    ) {
        unregister()

        self.handler = handler
        self.isRegistered = true

        // Create an event monitor for keyDown events
        eventMonitor = EventMonitor(modifiers: modifiers, key: key) { [weak self] event in
            self?.handler?()
        }
        eventMonitor?.start()
    }

    /// Unregister the global hotkey handler
    func unregister() {
        eventMonitor?.stop()
        eventMonitor = nil
        isRegistered = false
        handler = nil
    }

    deinit {
        unregister()
    }
}

// MARK: - Event Monitor

/// Monitors global key events
class EventMonitor {

    private var monitor: Any?
    private let modifiers: NSEvent.ModifierFlags
    private let key: KeyEquivalent
    private let handler: (NSEvent) -> Void

    init(modifiers: NSEvent.ModifierFlags, key: KeyEquivalent, handler: @escaping (NSEvent) -> Void) {
        self.modifiers = modifiers
        self.key = key
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            print("[HotKey] Event received: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")

            // Check if the pressed key matches
            if event.keyCode == self.key.keyCode {
                // Check if modifiers match - use contains for flexibility
                let hasCommand = event.modifierFlags.contains(.command)
                let hasShift = event.modifierFlags.contains(.shift)

                print("[HotKey] Key=\(self.key.character), hasCommand=\(hasCommand), hasShift=\(hasShift)")

                if hasCommand && hasShift {
                    print("[HotKey] Hotkey triggered!")
                    self.handler(event)
                }
            }
        }
        print("[HotKey] Monitor started for key: \(key.character) (keyCode: \(key.keyCode))")
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

// MARK: - Key Equivalent

struct KeyEquivalent {
    let character: Character
    let keyCode: UInt16

    static let k = KeyEquivalent(character: "k", keyCode: 37)
    static let s = KeyEquivalent(character: "s", keyCode: 1)
    static let c = KeyEquivalent(character: "c", keyCode: 8)
    static let i = KeyEquivalent(character: "i", keyCode: 34) // I for color picker
    static let escape = KeyEquivalent(character: "\u{001B}", keyCode: 53)
    static let `return` = KeyEquivalent(character: "\n", keyCode: 36)

    // Pin window shortcuts
    static let f3 = KeyEquivalent(character: "\u{F3}", keyCode: 118) // F3
}

// MARK: - Modifier Flags Extension

extension NSEvent.ModifierFlags {
    /// Get the command modifier
    static let command: NSEvent.ModifierFlags = .command
    /// Get the shift modifier
    static let shift: NSEvent.ModifierFlags = .shift
    /// Get the option modifier
    static let option: NSEvent.ModifierFlags = .option
    /// Get the control modifier
    static let control: NSEvent.ModifierFlags = .control
}
