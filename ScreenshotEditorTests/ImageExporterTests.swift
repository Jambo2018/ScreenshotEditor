//
//  ImageExporterTests.swift
//  ScreenshotEditorTests
//

import XCTest
import SwiftUI
import AppKit
@testable import ScreenshotEditor

final class ImageExporterTests: XCTestCase {

    func testExportWithEmptyImageThrows() {
        XCTAssertThrowsError(
            try ImageExporter.exportImage(
                sourceImage: NSImage(),
                backgroundType: .color,
                gradientColors: [.blue],
                backgroundImage: nil,
                blurAmount: 0,
                padding: 40,
                cornerRadius: 12,
                showShadow: true,
                showBorder: false,
                deviceFrame: .none,
                aspectRatio: .original,
                customAspectRatio: CGSize(width: 4, height: 5),
                annotations: [],
                format: .png
            )
        )
    }

    func testRenderImageAppliesPaddingToOriginalAspectRatio() throws {
        let sourceImage = makeImage(width: 100, height: 50)
        let sourcePixelSize = sourceImage.pixelSize
        let rendered = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .color,
            gradientColors: [.blue],
            backgroundImage: nil,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .original,
            customAspectRatio: CGSize(width: 4, height: 5)
        )

        XCTAssertEqual(rendered.size.width, sourcePixelSize.width + 40, accuracy: 0.001)
        XCTAssertEqual(rendered.size.height, sourcePixelSize.height + 40, accuracy: 0.001)
    }

    func testRenderImageHonorsRequestedCanvasAspectRatio() throws {
        let sourceImage = makeImage(width: 100, height: 50)
        let sourcePixelSize = sourceImage.pixelSize
        let minimumCanvasWidth = sourcePixelSize.width + 40
        let minimumCanvasHeight = sourcePixelSize.height + 40
        let expectedSide = max(minimumCanvasWidth, minimumCanvasHeight)
        let rendered = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .color,
            gradientColors: [.blue],
            backgroundImage: nil,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .square,
            customAspectRatio: CGSize(width: 4, height: 5)
        )

        XCTAssertEqual(rendered.size.width, expectedSide, accuracy: 0.001)
        XCTAssertEqual(rendered.size.height, expectedSide, accuracy: 0.001)
    }

    func testPreviewRenderAndExportUseSameCanvasDimensions() throws {
        let sourceImage = makeImage(width: 160, height: 90)

        let preview = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .image,
            gradientColors: [.purple, .pink],
            backgroundImage: makeImage(width: 240, height: 240, color: .systemOrange),
            blurAmount: 18,
            padding: 32,
            cornerRadius: 14,
            showShadow: true,
            showBorder: true,
            deviceFrame: .iphone,
            aspectRatio: .portrait34,
            customAspectRatio: CGSize(width: 4, height: 5),
            annotations: []
        )

        let exportedData = try ImageExporter.exportImage(
            sourceImage: sourceImage,
            backgroundType: .image,
            gradientColors: [.purple, .pink],
            backgroundImage: makeImage(width: 240, height: 240, color: .systemOrange),
            blurAmount: 18,
            padding: 32,
            cornerRadius: 14,
            showShadow: true,
            showBorder: true,
            deviceFrame: .iphone,
            aspectRatio: .portrait34,
            customAspectRatio: CGSize(width: 4, height: 5),
            annotations: [],
            format: .png
        )

        let exportedPixelSize = try XCTUnwrap(pixelSize(from: exportedData))

        XCTAssertEqual(preview.size.width, exportedPixelSize.width, accuracy: 0.001)
        XCTAssertEqual(preview.size.height, exportedPixelSize.height, accuracy: 0.001)
    }

    func testDeviceFrameIncreasesRenderedCanvasSize() throws {
        let sourceImage = makeImage(width: 120, height: 80)

        let unframed = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .color,
            gradientColors: [.blue],
            backgroundImage: nil,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .original,
            customAspectRatio: CGSize(width: 4, height: 5)
        )

        let framed = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .color,
            gradientColors: [.blue],
            backgroundImage: nil,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            deviceFrame: .iphone,
            aspectRatio: .original,
            customAspectRatio: CGSize(width: 4, height: 5)
        )

        XCTAssertGreaterThan(framed.size.width, unframed.size.width)
        XCTAssertGreaterThan(framed.size.height, unframed.size.height)
    }

    func testCustomAspectRatioUsesProvidedDimensions() throws {
        let rendered = try ImageExporter.renderImage(
            sourceImage: makeImage(width: 120, height: 80),
            backgroundType: .none,
            gradientColors: [.blue],
            backgroundImage: nil,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .custom,
            customAspectRatio: CGSize(width: 16, height: 9)
        )

        XCTAssertEqual(rendered.size.width / rendered.size.height, 16.0 / 9.0, accuracy: 0.01)
    }

    func testImageBackgroundRenderMatchesExportedPixelDimensions() throws {
        let sourceImage = makeImage(width: 180, height: 120)

        let rendered = try ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: .image,
            gradientColors: [.blue, .purple],
            backgroundImage: makeImage(width: 220, height: 220, color: .systemPink),
            blurAmount: 24,
            padding: 28,
            cornerRadius: 16,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .landscape169,
            customAspectRatio: CGSize(width: 4, height: 5)
        )

        let exported = try ImageExporter.exportImage(
            sourceImage: sourceImage,
            backgroundType: .image,
            gradientColors: [.blue, .purple],
            backgroundImage: makeImage(width: 220, height: 220, color: .systemPink),
            blurAmount: 24,
            padding: 28,
            cornerRadius: 16,
            showShadow: false,
            showBorder: false,
            deviceFrame: .none,
            aspectRatio: .landscape169,
            customAspectRatio: CGSize(width: 4, height: 5),
            annotations: [],
            format: .png
        )

        let exportedSize = try XCTUnwrap(pixelSize(from: exported))
        XCTAssertEqual(rendered.size.width, exportedSize.width, accuracy: 0.001)
        XCTAssertEqual(rendered.size.height, exportedSize.height, accuracy: 0.001)
    }

    private func pixelSize(from data: Data) -> CGSize? {
        guard let rep = NSBitmapImageRep(data: data) else { return nil }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }

    private func makeImage(width: CGFloat, height: CGFloat, color: NSColor = .systemBlue) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        color.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
        image.unlockFocus()
        return image
    }
}
