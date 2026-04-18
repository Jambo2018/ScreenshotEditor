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

enum EditorDeviceClass: Equatable {
    case phone
    case tablet
    case desktop

    var canvasPadding: EdgeInsets {
        switch self {
        case .phone:
            return EdgeInsets()
        case .tablet:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .desktop:
            return EdgeInsets(
                top: EditorSpacing.xLarge,
                leading: EditorSpacing.xxLarge,
                bottom: EditorSpacing.xLarge,
                trailing: EditorSpacing.xxLarge
            )
        }
    }

    var topBarPadding: EdgeInsets {
        switch self {
        case .phone:
            return EdgeInsets(
                top: 0,
                leading: 6,
                bottom: 3,
                trailing: 6
            )
        case .tablet:
            return EdgeInsets(
                top: 2,
                leading: EditorSpacing.small,
                bottom: 4,
                trailing: EditorSpacing.small
            )
        case .desktop:
            return EdgeInsets(
                top: EditorSpacing.xLarge,
                leading: EditorSpacing.xxLarge,
                bottom: EditorSpacing.xLarge,
                trailing: EditorSpacing.xxLarge
            )
        }
    }

    var topBarButtonSide: CGFloat {
        switch self {
        case .phone:
            return 26
        case .tablet:
            return 28
        case .desktop:
            return 32
        }
    }

    var workspaceHorizontalPadding: CGFloat {
        switch self {
        case .phone:
            return EditorSpacing.medium
        case .tablet:
            return EditorSpacing.xLarge
        case .desktop:
            return EditorSpacing.xxLarge
        }
    }

    var workspaceVerticalPadding: CGFloat {
        switch self {
        case .phone:
            return 4
        case .tablet:
            return 6
        case .desktop:
            return EditorSpacing.xLarge
        }
    }

    var workspacePrimarySpacing: CGFloat {
        switch self {
        case .phone:
            return 4
        case .tablet:
            return 6
        case .desktop:
            return EditorSpacing.large
        }
    }

    var workspaceSectionWidth: CGFloat? {
        switch self {
        case .phone:
            return nil
        case .tablet:
            return 248
        case .desktop:
            return 332
        }
    }

    var previewPadding: CGFloat {
        switch self {
        case .phone:
            return 0
        case .tablet:
            return 0
        case .desktop:
            return EditorSpacing.xxLarge
        }
    }

    var bottomBarHorizontalPadding: CGFloat {
        switch self {
        case .phone:
            return 6
        case .tablet:
            return EditorSpacing.small
        case .desktop:
            return EditorSpacing.xxxLarge
        }
    }

    var bottomBarVerticalPadding: CGFloat {
        switch self {
        case .phone:
            return 3
        case .tablet:
            return 4
        case .desktop:
            return EditorSpacing.xLarge
        }
    }

    var bottomBarActionSpacing: CGFloat {
        switch self {
        case .phone:
            return 4
        case .tablet:
            return 5
        case .desktop:
            return EditorSpacing.medium
        }
    }

    var bottomBarSpacing: CGFloat {
        switch self {
        case .phone:
            return 0
        case .tablet:
            return EditorSpacing.small
        case .desktop:
            return EditorSpacing.xLarge
        }
    }

    var bottomBarToolSpacing: CGFloat {
        switch self {
        case .phone:
            return 4
        case .tablet:
            return 5
        case .desktop:
            return EditorSpacing.small
        }
    }

    var bottomBarSeparatorHeight: CGFloat {
        switch self {
        case .phone:
            return 0
        case .tablet:
            return 18
        case .desktop:
            return 34
        }
    }

    var actionTitleSize: CGFloat {
        switch self {
        case .phone:
            return 9
        case .tablet:
            return 10
        case .desktop:
            return 16
        }
    }

    var actionIconSize: CGFloat {
        switch self {
        case .phone:
            return 9
        case .tablet:
            return 10
        case .desktop:
            return 16
        }
    }

    var buttonIconSpacing: CGFloat {
        switch self {
        case .phone:
            return 2
        case .tablet:
            return 3
        case .desktop:
            return EditorSpacing.small
        }
    }

    var actionHorizontalPadding: CGFloat {
        switch self {
        case .phone:
            return 7
        case .tablet:
            return EditorSpacing.small
        case .desktop:
            return EditorSpacing.xxLarge
        }
    }

    var actionVerticalPadding: CGFloat {
        switch self {
        case .phone:
            return 4
        case .tablet:
            return 5
        case .desktop:
            return EditorSpacing.large
        }
    }

    var actionCornerRadius: CGFloat {
        switch self {
        case .phone, .tablet:
            return EditorCornerRadius.compact
        case .desktop:
            return EditorCornerRadius.panel
        }
    }

    var toolIconSize: CGFloat {
        switch self {
        case .phone:
            return 9
        case .tablet:
            return 10
        case .desktop:
            return 15
        }
    }

    var toolButtonSize: CGFloat {
        switch self {
        case .phone:
            return 24
        case .tablet:
            return 24
        case .desktop:
            return 38
        }
    }

    var toolCornerRadius: CGFloat {
        switch self {
        case .phone, .tablet:
            return 7
        case .desktop:
            return EditorCornerRadius.xLarge
        }
    }
}

enum EditorSpacing {
    static let micro: CGFloat = 2
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 6
    static let small: CGFloat = 8
    static let medium: CGFloat = 10
    static let large: CGFloat = 12
    static let xLarge: CGFloat = 14
    static let xxLarge: CGFloat = 18
    static let xxxLarge: CGFloat = 20
}

enum EditorCornerRadius {
    static let tiny: CGFloat = 4
    static let compact: CGFloat = 6
    static let small: CGFloat = 8
    static let medium: CGFloat = 10
    static let xLarge: CGFloat = 12
    static let panel: CGFloat = 14
}

enum EditorOpacity {
    static let subtleFill: Double = 0.08
    static let accentFill: Double = 0.12
    static let panelFill: Double = 0.07
    static let selectedFill: Double = 0.18
    static let separator: Double = 0.28
    static let toolbar: Double = 0.98
    static let swatchIdleStroke: Double = 0.22
    static let swatchStrongStroke: Double = 0.28
}

enum EditorTypography {
    static let microLabel = Font.system(size: 9, weight: .semibold)
    static let compactLabel = Font.system(size: 10, weight: .semibold)
    static let sectionLabel = Font.system(size: 11, weight: .semibold)
    static let welcomeButton = Font.system(size: 12, weight: .semibold)
    static let statusChip = Font.system(size: 10, weight: .semibold)

    static func topBarTitle(for deviceClass: EditorDeviceClass) -> Font {
        switch deviceClass {
        case .phone:
            return .system(size: 12, weight: .semibold)
        case .tablet:
            return .system(size: 13, weight: .semibold)
        case .desktop:
            return .headline
        }
    }

    static func topBarSubtitle(for deviceClass: EditorDeviceClass) -> Font {
        switch deviceClass {
        case .phone:
            return .system(size: 9)
        case .tablet:
            return .system(size: 10)
        case .desktop:
            return .caption
        }
    }

    static func workspaceTitle(for deviceClass: EditorDeviceClass) -> Font {
        switch deviceClass {
        case .phone:
            return .system(size: 11, weight: .semibold)
        case .tablet:
            return .system(size: 12, weight: .semibold)
        case .desktop:
            return .headline
        }
    }

    static func workspaceSubtitle(for deviceClass: EditorDeviceClass) -> Font {
        switch deviceClass {
        case .phone:
            return .system(size: 9)
        case .tablet:
            return .system(size: 10)
        case .desktop:
            return .caption
        }
    }
}
