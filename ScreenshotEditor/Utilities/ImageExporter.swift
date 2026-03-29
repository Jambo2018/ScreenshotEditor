//
//  ImageExporter.swift
//  ScreenshotEditor
//
//  Handles image export with background, effects, and formatting
//

import SwiftUI
import AppKit
import CoreImage

class ImageExporter {

    enum ExportError: Error {
        case noImage
        case exportFailed
        case saveFailed
    }

    /// Export image with all effects applied
    static func exportImage(
        sourceImage: NSImage,
        backgroundType: BackgroundType,
        gradient: GradientPreset,
        solidColor: Color,
        blurAmount: Double,
        padding: Double,
        cornerRadius: Double,
        showShadow: Bool,
        showBorder: Bool,
        format: ImageFormat
    ) throws -> Data {

        print("[Export] Starting export...")
        print("[Export] Source image size: \(sourceImage.size)")

        // Get CGImage from NSImage
        guard let cgImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[Export] ERROR: Failed to get CGImage")
            throw ExportError.noImage
        }

        print("[Export] Got CGImage: \(cgImage.width)x\(cgImage.height)")

        let ciImage = CIImage(cgImage: cgImage)

        // Calculate output size with padding
        let sourceSize = sourceImage.size
        let outputWidth = sourceSize.width + (padding * 2)
        let outputHeight = sourceSize.height + (padding * 2)
        let outputSize = CGSize(width: outputWidth, height: outputHeight)

        print("[Export] Output size: \(outputSize)")
        print("[Export] Background type: \(backgroundType)")

        // Create background
        let backgroundImage = createBackground(
            type: backgroundType,
            gradient: gradient,
            solidColor: solidColor,
            size: outputSize,
            blurAmount: blurAmount
        )

        // Create composition with positioning
        let positionedImage = ciImage.transformed(by: CGAffineTransform(translationX: padding, y: padding))

        guard let composition = CIFilter(name: "CISourceOverCompositing") else {
            throw ExportError.exportFailed
        }
        composition.setValue(positionedImage, forKey: kCIInputImageKey)
        composition.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)

        guard let composedImage = composition.outputImage else {
            throw ExportError.exportFailed
        }

        // Create context and render
        let context = CIContext(options: [:])
        let finalBounds = CGRect(origin: .zero, size: outputSize)

        print("[Export] Creating CGImage from composed image...")

        guard let renderedCGImage = context.createCGImage(composedImage, from: finalBounds) else {
            print("[Export] ERROR: Failed to create CGImage from composition")
            throw ExportError.exportFailed
        }

        print("[Export] Created CGImage: \(renderedCGImage.width)x\(renderedCGImage.height)")

        // Apply corner radius
        let roundedImage = applyCornerRadius(renderedCGImage, radius: cornerRadius, size: outputSize)

        // Apply shadow if needed
        let finalImage = showShadow ? applyShadow(roundedImage, cornerRadius: cornerRadius, size: outputSize) : roundedImage

        print("[Export] Final image processing complete")

        // Convert to data
        return try imageToData(finalImage, format: format)
    }

    // MARK: - Background Creation

    private static func createBackground(
        type: BackgroundType,
        gradient: GradientPreset,
        solidColor: Color,
        size: CGSize,
        blurAmount: Double
    ) -> CIImage {

        switch type {
        case .gradient:
            return createGradientBackground(colors: gradient.colors, size: size)
        case .solid:
            return createSolidBackground(color: solidColor, size: size)
        case .blur:
            return createBlurBackground(blurAmount: blurAmount, size: size)
        case .image:
            return createGradientBackground(colors: gradient.colors, size: size)
        }
    }

    private static func createGradientBackground(colors: [Color], size: CGSize) -> CIImage {
        // Convert SwiftUI Colors to CGColors
        let cgColors: [CGColor] = colors.map { NSColor($0).cgColor }

        guard cgColors.count >= 2 else {
            return createSolidBackground(color: .white, size: size)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: [0.0, 1.0]) else {
            return createSolidBackground(color: .white, size: size)
        }

        let contextSize = CGSize(width: size.width, height: size.height)
        guard let context = CGContext(
            data: nil,
            width: Int(contextSize.width),
            height: Int(contextSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return createSolidBackground(color: .white, size: size)
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )

        guard let cgImage = context.makeImage() else {
            let white = CIColor(red: 0.5, green: 0.5, blue: 0.5)
            return CIImage(color: white)
                .cropped(to: CGRect(origin: .zero, size: size))
        }

        return CIImage(cgImage: cgImage)
    }

    private static func createSolidBackground(color: Color, size: CGSize) -> CIImage {
        let nsColor = NSColor(color)
        let ciColor = CIColor(color: nsColor) ?? CIColor(red: 1, green: 1, blue: 1)
        return CIImage(color: ciColor)
            .cropped(to: CGRect(origin: .zero, size: size))
    }

    private static func createBlurBackground(blurAmount: Double, size: CGSize) -> CIImage {
        let baseColor = CIColor(red: 0.8, green: 0.8, blue: 0.8) ?? CIColor(red: 0.5, green: 0.5, blue: 0.5)
        let baseImage = CIImage(color: baseColor)
            .cropped(to: CGRect(origin: .zero, size: size))

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return baseImage
        }
        blurFilter.setValue(baseImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurAmount / 10, forKey: kCIInputRadiusKey)

        return blurFilter.outputImage ?? baseImage
    }

    // MARK: - Corner Radius

    private static func applyCornerRadius(_ image: CGImage, radius: Double, size: CGSize) -> CGImage {
        guard radius > 0 else { return image }

        let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        let path = CGPath(
            roundedRect: CGRect(origin: .zero, size: size),
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        context.addPath(path)
        context.clip()
        context.draw(image, in: CGRect(origin: .zero, size: size))

        return context.makeImage()!
    }

    // MARK: - Shadow

    private static func applyShadow(_ image: CGImage, cornerRadius: Double, size: CGSize) -> CGImage {
        let shadowOffset: CGFloat = 10
        let shadowBlur: CGFloat = 20
        let shadowSize = CGSize(width: size.width + shadowOffset * 2 + shadowBlur * 2,
                               height: size.height + shadowOffset * 2 + shadowBlur * 2)

        let context = CGContext(
            data: nil,
            width: Int(shadowSize.width),
            height: Int(shadowSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Draw shadow
        let shadowRect = CGRect(x: shadowOffset + shadowBlur, y: shadowOffset + shadowBlur,
                               width: size.width, height: size.height)
        let shadowPath = CGPath(
            roundedRect: shadowRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        context.setShadow(offset: CGSize(width: 0, height: -shadowOffset), blur: shadowBlur,
                         color: NSColor.black.withAlphaComponent(0.3).cgColor)
        context.addPath(shadowPath)
        context.setFillColor(NSColor.clear.cgColor)
        context.fillPath(using: .evenOdd)

        // Draw image
        context.draw(image, in: shadowRect)

        return context.makeImage()!
    }

    // MARK: - Format Conversion

    private static func imageToData(_ image: CGImage, format: ImageFormat) throws -> Data {
        let bitmapRep = NSBitmapImageRep(cgImage: image)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:]) ?? Data()
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) ?? Data()
        case .webp:
            // WebP not natively supported, fallback to PNG
            return bitmapRep.representation(using: .png, properties: [:]) ?? Data()
        }
    }
}
