//
//  Screenshot.swift
//  ScreenshotEditor
//
//  Model representing a screenshot image
//

import SwiftUI
import AppKit

struct Screenshot: Identifiable {
    let id: UUID
    let name: String
    let sourceURL: URL
    let createdAt: Date
    let image: NSImage?

    // Computed
    var thumbnail: NSImage? {
        guard let image = image else { return nil }
        let thumbnailSize = NSSize(width: 200, height: 150)
        return image.resized(to: thumbnailSize)
    }
}

// MARK: - NSImage Extension

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
