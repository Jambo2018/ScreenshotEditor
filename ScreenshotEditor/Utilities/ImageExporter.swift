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
    ///
    /// Effect order matches CanvasView preview:
    /// 1. Background (with optional blur)
    /// 2. Source image with padding, corner radius, shadow, border
    /// 3. Device frame overlay (if enabled)
    static func exportImage(
        sourceImage: NSImage,
        backgroundType: BackgroundType,
        gradient: GradientPreset,
        solidColor: Color,
        backgroundImage: NSImage?,
        blurAmount: Double,
        padding: Double,
        cornerRadius: Double,
        showShadow: Bool,
        showBorder: Bool,
        deviceFrame: DeviceFrame,
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

        // Calculate output size with padding
        let sourceSize = sourceImage.size
        let outputWidth = sourceSize.width + (padding * 2)
        let outputHeight = sourceSize.height + (padding * 2)
        let outputSize = CGSize(width: outputWidth, height: outputHeight)

        print("[Export] Output size: \(outputSize)")
        print("[Export] Background type: \(backgroundType)")

        // Step 1: Create background
        let backgroundCI = createBackground(
            type: backgroundType,
            gradient: gradient,
            solidColor: solidColor,
            backgroundImage: backgroundImage,
            size: outputSize,
            blurAmount: blurAmount
        )

        // Step 2: Apply corner radius to source image FIRST (matches CanvasView)
        let sourceCGImage = cgImage
        let roundedSource = cornerRadius > 0 ? applyCornerRadius(sourceCGImage, radius: cornerRadius, size: sourceSize) : sourceCGImage

        // Step 3: Apply shadow to rounded source (matches CanvasView order)
        let sourceWithShadow = showShadow ? applyShadowToSource(roundedSource, cornerRadius: cornerRadius, padding: padding) : roundedSource

        // Step 4: Create positioned source image with padding
        let positionedImage = CIImage(cgImage: sourceWithShadow)
            .transformed(by: CGAffineTransform(translationX: padding, y: padding))

        // Step 5: Composite source over background
        guard let composition = CIFilter(name: "CISourceOverCompositing") else {
            throw ExportError.exportFailed
        }
        composition.setValue(positionedImage, forKey: kCIInputImageKey)
        composition.setValue(backgroundCI, forKey: kCIInputBackgroundImageKey)

        guard let composedImage = composition.outputImage else {
            throw ExportError.exportFailed
        }

        // Step 6: Render composition
        let context = CIContext(options: [:])
        let finalBounds = CGRect(origin: .zero, size: outputSize)

        print("[Export] Creating CGImage from composed image...")

        guard let renderedCGImage = context.createCGImage(composedImage, from: finalBounds) else {
            print("[Export] ERROR: Failed to create CGImage from composition")
            throw ExportError.exportFailed
        }

        print("[Export] Created CGImage: \(renderedCGImage.width)x\(renderedCGImage.height)")

        // Step 7: Apply border on top (matches CanvasView overlay stroke)
        let borderedImage = showBorder ? applyBorderOnTop(renderedCGImage, radius: cornerRadius, size: outputSize, padding: padding) : renderedCGImage

        // Step 8: Apply device frame if needed
        let finalImage: CGImage
        if deviceFrame != .none {
            finalImage = applyDeviceFrame(borderedImage, frame: deviceFrame, size: outputSize)
        } else {
            finalImage = borderedImage
        }

        print("[Export] Final image processing complete")

        // Convert to data
        return try imageToData(finalImage, format: format)
    }

    // MARK: - Background Creation

    private static func createBackground(
        type: BackgroundType,
        gradient: GradientPreset,
        solidColor: Color,
        backgroundImage: NSImage?,
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
            return createImageBackground(backgroundImage: backgroundImage, size: size)
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
        let baseColor = CIColor(red: 0.8, green: 0.8, blue: 0.8)
        let baseImage = CIImage(color: baseColor)
            .cropped(to: CGRect(origin: .zero, size: size))

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return baseImage
        }
        blurFilter.setValue(baseImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurAmount / 10, forKey: kCIInputRadiusKey)

        return blurFilter.outputImage ?? baseImage
    }

    private static func createImageBackground(backgroundImage: NSImage?, size: CGSize) -> CIImage {
        guard let image = backgroundImage else {
            // Fallback to solid color if no image provided
            return createSolidBackground(color: .gray, size: size)
        }

        // Convert NSImage to CIImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return createSolidBackground(color: .gray, size: size)
        }

        var ciImage = CIImage(cgImage: cgImage)

        // Scale background image to fill the size (aspect fill)
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scale = max(scaleX, scaleY)

        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Center the image
        let posX = (size.width - scaledImage.extent.width) / 2
        let posY = (size.height - scaledImage.extent.height) / 2

        ciImage = scaledImage.transformed(by: CGAffineTransform(translationX: posX, y: posY))

        // Crop to exact size
        return ciImage.cropped(to: CGRect(origin: .zero, size: size))
    }

    // MARK: - Corner Radius

    /// Apply corner radius to source image only (before compositing)
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

    /// Apply shadow to source image with padding offset (matches CanvasView .shadow modifier)
    private static func applyShadowToSource(_ image: CGImage, cornerRadius: Double, padding: Double) -> CGImage {
        // CanvasView uses: .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        let shadowOffset: CGFloat = 10
        let shadowBlur: CGFloat = 20
        let extraWidth = shadowOffset * 2 + shadowBlur * 2
        let extraHeight = shadowOffset * 2 + shadowBlur * 2
        let shadowWidth = CGFloat(image.width) + extraWidth
        let shadowHeight = CGFloat(image.height) + extraHeight
        let shadowSize = CGSize(width: shadowWidth, height: shadowHeight)

        let context = CGContext(
            data: nil,
            width: Int(shadowSize.width),
            height: Int(shadowSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Draw shadow first (offset down by 10px)
        let imageX = shadowOffset + shadowBlur
        let imageY = shadowOffset + shadowBlur
        let imageRect = CGRect(x: imageX, y: imageY, width: CGFloat(image.width), height: CGFloat(image.height))
        let shadowPath = CGPath(
            roundedRect: imageRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        context.setShadow(offset: CGSize(width: 0, height: shadowOffset), blur: shadowBlur,
                         color: NSColor.black.withAlphaComponent(0.3).cgColor)
        context.addPath(shadowPath)
        context.setFillColor(NSColor.white.cgColor)
        context.fillPath()

        // Draw image on top (clear shadow)
        context.setShadow(offset: .zero, blur: 0)
        context.draw(image, in: imageRect)

        return context.makeImage()!
    }

    /// Apply border stroke on top of composed image (matches CanvasView .overlay stroke)
    private static func applyBorderOnTop(_ image: CGImage, radius: Double, size: CGSize, padding: Double) -> CGImage {
        let borderWidth: CGFloat = 1

        let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Draw the image first
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))

        // Draw border path around the source image area (with padding offset)
        let sourceRect = CGRect(x: padding, y: padding, width: size.width - padding * 2, height: size.height - padding * 2)
        let borderPath = CGPath(
            roundedRect: sourceRect,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        context.addPath(borderPath)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(borderWidth)
        context.strokePath()

        return context.makeImage()!
    }

    // MARK: - Device Frame

    private static func applyDeviceFrame(_ image: CGImage, frame: DeviceFrame, size: CGSize) -> CGImage {
        // Calculate device frame dimensions
        let (frameSize, insetRect, deviceColor) = getDeviceFrameDimensions(for: frame, imageSize: size)

        let context = CGContext(
            data: nil,
            width: Int(frameSize.width),
            height: Int(frameSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        // Fill with transparent background
        context.setFillColor(CGColor.clear)
        context.fill(CGRect(origin: .zero, size: frameSize))

        // Draw device body
        context.setFillColor(deviceColor)
        let devicePath = CGPath(roundedRect: CGRect(origin: .zero, size: frameSize), cornerWidth: 20, cornerHeight: 20, transform: nil)
        context.addPath(devicePath)
        context.fillPath()

        // Draw screen area (where the image shows)
        context.setBlendMode(.normal)
        context.draw(image, in: insetRect)

        // Draw screen bezel
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(2)
        let screenPath = CGPath(roundedRect: insetRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        context.addPath(screenPath)
        context.strokePath()

        // Add device-specific details
        switch frame {
        case .iphone:
            addIPhoneDetails(to: context, frameSize: frameSize)
        case .macbook:
            addMacBookDetails(to: context, frameSize: frameSize)
        case .none:
            break
        }

        return context.makeImage()!
    }

    private static func getDeviceFrameDimensions(for deviceFrame: DeviceFrame, imageSize: CGSize) -> (frameSize: CGSize, insetRect: CGRect, color: CGColor) {
        switch deviceFrame {
        case .iphone:
            // iPhone frame: 20pt bezel on sides, 30pt top/bottom
            let bezelSide: CGFloat = 20
            let bezelTopBottom: CGFloat = 30
            let frameWidth = imageSize.width + (bezelSide * 2)
            let frameHeight = imageSize.height + (bezelTopBottom * 2)
            let insetRect = CGRect(x: bezelSide, y: bezelTopBottom, width: imageSize.width, height: imageSize.height)
            return (CGSize(width: frameWidth, height: frameHeight), insetRect, NSColor.black.cgColor)

        case .macbook:
            // MacBook frame: larger bottom "chin"
            let bezelSide: CGFloat = 15
            let bezelTop: CGFloat = 20
            let bezelBottom: CGFloat = 40  // MacBook chin
            let frameWidth = imageSize.width + (bezelSide * 2)
            let frameHeight = imageSize.height + bezelTop + bezelBottom
            let insetRect = CGRect(x: bezelSide, y: bezelTop, width: imageSize.width, height: imageSize.height)
            return (CGSize(width: frameWidth, height: frameHeight), insetRect, NSColor.darkGray.cgColor)

        case .none:
            return (imageSize, CGRect(origin: .zero, size: imageSize), NSColor.clear.cgColor)
        }
    }

    private static func addIPhoneDetails(to context: CGContext, frameSize: CGSize) {
        // Top notch
        let notchWidth: CGFloat = 100
        let notchHeight: CGFloat = 20
        let notchX = (frameSize.width - notchWidth) / 2
        let notchRect = CGRect(x: notchX, y: 0, width: notchWidth, height: notchHeight)
        context.setFillColor(NSColor.black.cgColor)
        context.fill(notchRect)

        // Bottom home indicator
        let indicatorWidth: CGFloat = 100
        let indicatorHeight: CGFloat = 4
        let indicatorX = (frameSize.width - indicatorWidth) / 2
        let indicatorY = frameSize.height - indicatorHeight - 8
        let indicatorRect = CGRect(x: indicatorX, y: indicatorY, width: indicatorWidth, height: indicatorHeight)
        let indicatorPath = CGPath(roundedRect: indicatorRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        context.addPath(indicatorPath)
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()
    }

    private static func addMacBookDetails(to context: CGContext, frameSize: CGSize) {
        // Bottom chin detail line
        let lineY = frameSize.height - 15
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.beginPath()
        context.move(to: CGPoint(x: 30, y: lineY))
        context.addLine(to: CGPoint(x: frameSize.width - 30, y: lineY))
        context.strokePath()
    }

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
