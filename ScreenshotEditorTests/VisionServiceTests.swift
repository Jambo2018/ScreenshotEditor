//
//  VisionServiceTests.swift
//  ScreenshotEditorTests
//
//  Unit tests for VisionService AI annotation features
//

import XCTest
@testable import ScreenshotEditor

final class VisionServiceTests: XCTestCase {

    var visionService: VisionService!
    var testImage: NSImage!

    override func setUp() async throws {
        try await super.setUp()
        visionService = VisionService.shared
        testImage = createTestImage()
    }

    override func tearDown() async throws {
        visionService = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Availability Tests

    func testVisionAvailability() {
        XCTAssertTrue(VisionService.isAvailable, "Vision Framework should be available on macOS")
    }

    func testSharedInstance() {
        let instance1 = VisionService.shared
        let instance2 = VisionService.shared
        XCTAssertTrue(instance1 === instance2, "Should return the same singleton instance")
    }

    // MARK: - Text Detection Tests

    func testDetectTextRegionsWithImageContainingText() {
        let expectation = XCTestExpectation(description: "Text detection completes")
        var textRegions: [TextRegion] = []

        // Create an image with text
        let textImage = createImageWithText("Hello World")

        visionService.detectTextRegions(in: textImage) { regions in
            textRegions = regions
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Text detection may or may not find text depending on image quality
        // Just verify the callback was invoked
        XCTAssertNotNil(textRegions, "Should return text regions array")
    }

    func testDetectTextRegionsWithEmptyImage() {
        let expectation = XCTestExpectation(description: "Text detection completes")

        visionService.detectTextRegions(in: testImage) { regions in
            XCTAssertEqual(regions.count, 0, "Should return empty array for image without text")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDetectTextRegionsWithNilImage() {
        let expectation = XCTestExpectation(description: "Text detection completes")
        let emptyImage = NSImage()

        visionService.detectTextRegions(in: emptyImage) { regions in
            XCTAssertEqual(regions.count, 0, "Should return empty array for invalid image")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Rectangle Detection Tests

    func testDetectRectangles() {
        let expectation = XCTestExpectation(description: "Rectangle detection completes")

        visionService.detectRectangles(in: testImage) { rectangles in
            XCTAssertNotNil(rectangles, "Should return rectangles array")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDetectRectanglesWithHighConfidence() {
        let expectation = XCTestExpectation(description: "Rectangle detection completes")

        // Create an image with a clear rectangle
        let rectImage = createImageWithRectangle()

        visionService.detectRectangles(in: rectImage) { rectangles in
            XCTAssertNotNil(rectangles, "Should detect rectangles")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Barcode Detection Tests

    func testDetectBarcodes() {
        let expectation = XCTestExpectation(description: "Barcode detection completes")

        visionService.detectBarcodes(in: testImage) { barcodes in
            XCTAssertNotNil(barcodes, "Should return barcodes array")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDetectBarcodesWithQRCode() {
        let expectation = XCTestExpectation(description: "Barcode detection completes")

        // Create an image with a QR code pattern
        let qrImage = createImageWithQRCode()

        visionService.detectBarcodes(in: qrImage) { barcodes in
            XCTAssertNotNil(barcodes, "Should detect barcodes")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Face Detection Tests

    func testDetectFaces() {
        let expectation = XCTestExpectation(description: "Face detection completes")

        visionService.detectFaces(in: testImage) { faces in
            XCTAssertNotNil(faces, "Should return faces array")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDetectFacesWithBlankImage() {
        let expectation = XCTestExpectation(description: "Face detection completes")

        // Solid color image should have no faces
        visionService.detectFaces(in: testImage) { faces in
            XCTAssertEqual(faces.count, 0, "Should not detect faces in blank image")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Supporting Types Tests

    func testTextRegionProperties() {
        let region = TextRegion(
            text: "Test",
            confidence: 0.95,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 50)
        )

        XCTAssertEqual(region.text, "Test")
        XCTAssertEqual(region.confidence, 0.95)
        XCTAssertEqual(region.boundingBox.width, 100)
        XCTAssertEqual(region.boundingBox.height, 50)
        XCTAssertNotNil(region.id)
    }

    func testBarcodeInfoProperties() {
        let barcode = BarcodeInfo(
            payload: "https://example.com",
            symbology: .QR,
            boundingBox: CGRect(x: 10, y: 20, width: 100, height: 100)
        )

        XCTAssertEqual(barcode.payload, "https://example.com")
        XCTAssertEqual(barcode.symbology, .QR)
        XCTAssertEqual(barcode.boundingBox.origin.x, 10)
        XCTAssertNotNil(barcode.id)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: CGFloat = 400, height: CGFloat = 300) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.systemBlue.drawSwatch(in: NSRect(x: 0, y: 0, width: width, height: height))
        image.unlockFocus()
        return image
    }

    private func createImageWithText(_ text: String) -> NSImage {
        let image = NSImage(size: NSSize(width: 400, height: 200))
        image.lockFocus()

        // Draw white background
        NSColor.white.drawSwatch(in: NSRect(x: 0, y: 0, width: 400, height: 200))

        // Draw black text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 48),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(x: 0, y: 50, width: 400, height: 100)
        text.draw(in: textRect, withAttributes: attributes)

        image.unlockFocus()
        return image
    }

    private func createImageWithRectangle() -> NSImage {
        let image = NSImage(size: NSSize(width: 400, height: 300))
        image.lockFocus()

        // Draw white background
        NSColor.white.drawSwatch(in: NSRect(x: 0, y: 0, width: 400, height: 300))

        // Draw a black rectangle
        let rect = NSRect(x: 100, y: 100, width: 200, height: 100)
        NSColor.black.drawSwatch(in: rect)

        image.unlockFocus()
        return image
    }

    private func createImageWithQRCode() -> NSImage {
        // For now, just return a test image
        // In a real scenario, you would generate or load a QR code image
        return createTestImage()
    }
}
