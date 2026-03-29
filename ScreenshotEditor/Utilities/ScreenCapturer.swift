//
//  ScreenCapturer.swift
//  ScreenshotEditor
//
//  Handles screen capture with permissions and region selection
//

import AppKit
import CoreGraphics
import ScreenCaptureKit

class ScreenCapturer {

    enum CaptureError: Error {
        case permissionDenied
        case captureFailed
        case invalidRegion
    }

    /// Check if screen recording permission is granted
    static func hasScreenRecordingPermission() -> Bool {
        // Check via CGPreflightScreenCaptureAccess
        return CGPreflightScreenCaptureAccess()
    }

    /// Request screen recording permission asynchronously
    static func requestPermission() async -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        return CGRequestScreenCaptureAccess()
    }

    /// Capture the entire screen
    static func captureScreen() -> CGImage? {
        // Use CGWindowListCreateImage for screen capture
        let rect = CGRect(x: 0, y: 0,
                         width: NSScreen.main?.frame.width ?? 1920,
                         height: NSScreen.main?.frame.height ?? 1080)

        return CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }

    /// Capture a specific region of the screen
    static func captureRegion(_ rect: CGRect) -> CGImage? {
        guard !rect.isNull && !rect.isInfinite && !rect.isEmpty else {
            return nil
        }

        return CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }

    /// Get all available screens with their dimensions
    static func getScreenInfo() -> [NSDictionary] {
        guard let windowInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return windowInfo.map { $0 as NSDictionary }
    }
}
