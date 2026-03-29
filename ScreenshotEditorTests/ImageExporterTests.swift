//
//  ImageExporterTests.swift
//  ScreenshotEditorTests
//
//  Unit tests for ImageExporter functionality
//

import XCTest
@testable import ScreenshotEditor

final class ImageExporterTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestImage(width: CGFloat = 100, height: CGFloat = 100) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.drawSwatch(in: NSRect(x: 0, y: 0, width: width, height: height))
        image.unlockFocus()
        return image
    }

    // MARK: - Export Error Cases

    func testExportWithNilImage() throws {
        // Test that exporting with an empty/nil image throws an error
        let emptyImage = NSImage()
        XCTAssertThrowsError(try ImageExporter.exportImage(
            sourceImage: emptyImage,
            backgroundType: .gradient,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 40,
            cornerRadius: 12,
            showShadow: true,
            showBorder: false,
            format: .png
        ))
    }

    // MARK: - Basic Export

    func testBasicPNGExport() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0, "Exported PNG data should not be empty")
    }

    func testJPEGExport() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .jpeg
        )

        XCTAssertGreaterThan(data.count, 0, "Exported JPEG data should not be empty")
        // JPEG should be smaller than PNG due to compression
        let pngData = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )
        XCTAssertLessThan(data.count, pngData.count, "JPEG should be smaller than PNG")
    }

    // MARK: - Background Types

    func testExportWithGradientBackground() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .gradient,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportWithSolidBackground() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .red,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportWithBlurBackground() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .blur,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 10,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Corner Radius

    func testExportWithCornerRadius() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 20,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportWithZeroCornerRadius() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Shadow

    func testExportWithShadow() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 12,
            showShadow: true,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportWithoutShadow() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 20,
            cornerRadius: 12,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Padding

    func testExportWithPadding() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 50,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportWithZeroPadding() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Gradient Presets

    func testAllGradientPresets() throws {
        let testImage = createTestImage()
        let gradients: [GradientPreset] = [.ocean, .sunset, .forest, .fire, .midnight]

        for gradient in gradients {
            let data = try ImageExporter.exportImage(
                sourceImage: testImage,
                backgroundType: .gradient,
                gradient: gradient,
                solidColor: .white,
                blurAmount: 0,
                padding: 20,
                cornerRadius: 0,
                showShadow: false,
                showBorder: false,
                format: .png
            )
            XCTAssertGreaterThan(data.count, 0, "Gradient \(gradient.name) should export successfully")
        }
    }

    // MARK: - Image Format

    func testWebPFallbackToPNG() throws {
        let testImage = createTestImage()

        let webpData = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .webp
        )

        XCTAssertGreaterThan(webpData.count, 0)
        // WebP fallback should produce PNG data
        let pngData = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .solid,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 0,
            padding: 0,
            cornerRadius: 0,
            showShadow: false,
            showBorder: false,
            format: .png
        )
        XCTAssertEqual(webpData.count, pngData.count, "WebP fallback should produce identical PNG data")
    }

    // MARK: - Combined Settings

    func testFullFeaturedExport() throws {
        let testImage = createTestImage()

        let data = try ImageExporter.exportImage(
            sourceImage: testImage,
            backgroundType: .gradient,
            gradient: .ocean,
            solidColor: .white,
            blurAmount: 5,
            padding: 40,
            cornerRadius: 12,
            showShadow: true,
            showBorder: false,
            format: .png
        )

        XCTAssertGreaterThan(data.count, 0)
    }
}
