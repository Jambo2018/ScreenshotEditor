//
//  Screenshot.swift
//  ScreenshotEditor
//
//  Model representing a screenshot image
//

import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformView = NSView
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#else
import UIKit
typealias PlatformImage = UIImage
typealias PlatformView = UIView
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#endif

struct Screenshot: Identifiable {
    let id: UUID
    let name: String
    let sourceURL: URL?
    let createdAt: Date
    let image: PlatformImage?

    // Computed
    var thumbnail: PlatformImage? {
        guard let image = image else { return nil }
        let thumbnailSize = CGSize(width: 200, height: 150)
        return image.resized(to: thumbnailSize)
    }
}

// MARK: - Platform Helpers

extension PlatformImage {
    static func load(contentsOf url: URL) -> PlatformImage? {
        #if os(macOS)
        NSImage(contentsOf: url)
        #else
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
        #endif
    }

    static func from(cgImage: CGImage, size: CGSize? = nil) -> PlatformImage {
        #if os(macOS)
        NSImage(cgImage: cgImage, size: size ?? CGSize(width: cgImage.width, height: cgImage.height))
        #else
        UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        #endif
    }

    var cgImageValue: CGImage? {
        #if os(macOS)
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return cgImage
        #endif
    }

    var pixelSize: CGSize {
        if let cgImageValue {
            return CGSize(width: cgImageValue.width, height: cgImageValue.height)
        }
        #if os(macOS)
        return size
        #else
        return CGSize(width: size.width * scale, height: size.height * scale)
        #endif
    }

    func resized(to newSize: CGSize) -> PlatformImage {
        #if os(macOS)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
        #else
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        #endif
    }

    func pngRepresentation() -> Data? {
        #if os(macOS)
        guard let cgImageValue else { return nil }
        return NSBitmapImageRep(cgImage: cgImageValue).representation(using: .png, properties: [:])
        #else
        return pngData()
        #endif
    }

    func jpegRepresentation(compressionQuality: CGFloat = 0.9) -> Data? {
        #if os(macOS)
        guard let cgImageValue else { return nil }
        return NSBitmapImageRep(cgImage: cgImageValue).representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #else
        return jpegData(compressionQuality: compressionQuality)
        #endif
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

extension PlatformColor {
    static func from(_ color: Color) -> PlatformColor {
        #if os(macOS)
        return NSColor(color)
        #else
        return UIColor(color)
        #endif
    }
}

extension Color {
    static var editorBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }

    static var editorPanelBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
}
