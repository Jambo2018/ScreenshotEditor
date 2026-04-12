//
//  ImageExporter.swift
//  ScreenshotEditor
//
//  Handles image export with background, effects, and formatting
//

import SwiftUI
import CoreImage

#if os(iOS)
import UIKit
#endif

class ImageExporter {

    enum ExportError: Error {
        case noImage
        case exportFailed
        case saveFailed
    }

    static func exportImage(
        sourceImage: PlatformImage,
        backgroundType: BackgroundType,
        gradientColors: [Color],
        backgroundImage: PlatformImage?,
        blurAmount: Double,
        padding: Double,
        cornerRadius: Double,
        showShadow: Bool,
        showBorder: Bool,
        deviceFrame: DeviceFrame,
        aspectRatio: ExportAspectRatio,
        customAspectRatio: CGSize,
        annotations: [Annotation],
        format: ImageFormat
    ) throws -> Data {
        let renderedImage = try renderCGImage(
            sourceImage: sourceImage,
            backgroundType: backgroundType,
            gradientColors: gradientColors,
            backgroundImage: backgroundImage,
            blurAmount: blurAmount,
            padding: padding,
            cornerRadius: cornerRadius,
            showShadow: showShadow,
            showBorder: showBorder,
            deviceFrame: deviceFrame,
            aspectRatio: aspectRatio,
            customAspectRatio: customAspectRatio,
            annotations: annotations
        )

        return try imageToData(renderedImage, format: format)
    }

    static func renderImage(
        sourceImage: PlatformImage,
        backgroundType: BackgroundType,
        gradientColors: [Color],
        backgroundImage: PlatformImage?,
        blurAmount: Double,
        padding: Double,
        cornerRadius: Double,
        showShadow: Bool,
        showBorder: Bool,
        deviceFrame: DeviceFrame,
        aspectRatio: ExportAspectRatio,
        customAspectRatio: CGSize,
        annotations: [Annotation] = []
    ) throws -> PlatformImage {
        let renderedImage = try renderCGImage(
            sourceImage: sourceImage,
            backgroundType: backgroundType,
            gradientColors: gradientColors,
            backgroundImage: backgroundImage,
            blurAmount: blurAmount,
            padding: padding,
            cornerRadius: cornerRadius,
            showShadow: showShadow,
            showBorder: showBorder,
            deviceFrame: deviceFrame,
            aspectRatio: aspectRatio,
            customAspectRatio: customAspectRatio,
            annotations: annotations
        )

        return PlatformImage.from(cgImage: renderedImage)
    }

    private static func renderCGImage(
        sourceImage: PlatformImage,
        backgroundType: BackgroundType,
        gradientColors: [Color],
        backgroundImage: PlatformImage?,
        blurAmount: Double,
        padding: Double,
        cornerRadius: Double,
        showShadow: Bool,
        showBorder: Bool,
        deviceFrame: DeviceFrame,
        aspectRatio: ExportAspectRatio,
        customAspectRatio: CGSize,
        annotations: [Annotation]
    ) throws -> CGImage {

        guard let cgImage = sourceImage.cgImageValue else {
            throw ExportError.noImage
        }

        let layout = calculateLayout(
            sourceSize: sourceImage.pixelSize,
            padding: padding,
            aspectRatio: aspectRatio,
            customAspectRatio: customAspectRatio
        )

        guard let context = CGContext(
            data: nil,
            width: Int(layout.canvasSize.width),
            height: Int(layout.canvasSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ExportError.exportFailed
        }

        drawBackground(
            in: context,
            type: backgroundType,
            gradientColors: gradientColors,
            backgroundImage: backgroundImage,
            blurAmount: blurAmount,
            size: layout.canvasSize
        )

        let roundedSource = cornerRadius > 0
            ? applyCornerRadius(cgImage, radius: cornerRadius)
            : cgImage

        if showShadow {
            context.saveGState()
            context.setShadow(
                offset: CGSize(width: 0, height: -10),
                blur: 20,
                color: PlatformColor.black.withAlphaComponent(0.3).cgColor
            )
            context.draw(roundedSource, in: layout.imageRect)
            context.restoreGState()
        } else {
            context.draw(roundedSource, in: layout.imageRect)
        }

        if showBorder {
            let borderPath = CGPath(
                roundedRect: layout.imageRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            context.addPath(borderPath)
            context.setStrokeColor(PlatformColor.white.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1)
            context.strokePath()
        }

        guard let composedImage = context.makeImage() else {
            throw ExportError.exportFailed
        }

        let framedImage: CGImage
        if deviceFrame != .none {
            framedImage = applyDeviceFrame(composedImage, frame: deviceFrame, size: layout.canvasSize)
        } else {
            framedImage = composedImage
        }

        let finalCanvasSize = CGSize(width: framedImage.width, height: framedImage.height)
        let annotatedImage = annotations.isEmpty
            ? framedImage
            : renderAnnotations(annotations, onto: framedImage, canvasSize: finalCanvasSize)

        return annotatedImage
    }

    // MARK: - Layout

    private static func calculateLayout(
        sourceSize: CGSize,
        padding: Double,
        aspectRatio: ExportAspectRatio,
        customAspectRatio: CGSize
    ) -> ExportLayout {
        let minimumCanvasWidth = sourceSize.width + (padding * 2)
        let minimumCanvasHeight = sourceSize.height + (padding * 2)

        guard let targetRatio = resolvedAspectRatioValue(for: aspectRatio, customAspectRatio: customAspectRatio) else {
            return ExportLayout(
                canvasSize: CGSize(width: minimumCanvasWidth, height: minimumCanvasHeight),
                imageRect: CGRect(x: padding, y: padding, width: sourceSize.width, height: sourceSize.height)
            )
        }

        let minimumRatio = minimumCanvasWidth / minimumCanvasHeight
        let canvasSize: CGSize

        if targetRatio >= minimumRatio {
            let canvasHeight = minimumCanvasHeight
            canvasSize = CGSize(width: canvasHeight * targetRatio, height: canvasHeight)
        } else {
            let canvasWidth = minimumCanvasWidth
            canvasSize = CGSize(width: canvasWidth, height: canvasWidth / targetRatio)
        }

        return ExportLayout(
            canvasSize: canvasSize,
            imageRect: CGRect(
                x: (canvasSize.width - sourceSize.width) / 2,
                y: (canvasSize.height - sourceSize.height) / 2,
                width: sourceSize.width,
                height: sourceSize.height
            )
        )
    }

    private static func resolvedAspectRatioValue(for aspectRatio: ExportAspectRatio, customAspectRatio: CGSize) -> CGFloat? {
        switch aspectRatio {
        case .original:
            return nil
        case .square:
            return 1
        case .portrait34:
            return 3.0 / 4.0
        case .landscape43:
            return 4.0 / 3.0
        case .portrait916:
            return 9.0 / 16.0
        case .landscape169:
            return 16.0 / 9.0
        case .custom:
            guard customAspectRatio.width > 0, customAspectRatio.height > 0 else { return nil }
            return customAspectRatio.width / customAspectRatio.height
        }
    }

    // MARK: - Backgrounds

    private static func drawBackground(
        in context: CGContext,
        type: BackgroundType,
        gradientColors: [Color],
        backgroundImage: PlatformImage?,
        blurAmount: Double,
        size: CGSize
    ) {
        let background: CGImage?

        switch type {
        case .none:
            background = nil
        case .color:
            let gradientBackground = createGradientBackground(colors: gradientColors, size: size)
            background = applyGaussianBlur(to: gradientBackground, blurAmount: blurAmount, size: size)
        case .image:
            let imageBackground = createImageBackground(backgroundImage: backgroundImage, size: size)
            background = applyGaussianBlur(to: imageBackground, blurAmount: blurAmount, size: size)
        }

        if let background {
            context.draw(background, in: CGRect(origin: .zero, size: size))
        }
    }

    private static func createGradientBackground(colors: [Color], size: CGSize) -> CGImage? {
        let cgColors = colors.map { PlatformColor.from($0).cgColor }

        guard !cgColors.isEmpty else {
            return createSolidBackground(color: .white, size: size)
        }

        if cgColors.count == 1 {
            return createSolidBackground(cgColor: cgColors[0], size: size)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: nil),
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
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

        return context.makeImage()
    }

    private static func createSolidBackground(color: Color, size: CGSize) -> CGImage? {
        createSolidBackground(cgColor: PlatformColor.from(color).cgColor, size: size)
    }

    private static func createSolidBackground(cgColor: CGColor, size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return context.makeImage()
    }

    private static func applyGaussianBlur(to image: CGImage?, blurAmount: Double, size: CGSize) -> CGImage? {
        guard let image else { return nil }
        guard blurAmount > 0 else { return image }

        let ciImage = CIImage(cgImage: image)
        let cropRect = CGRect(origin: .zero, size: size)
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return image
        }

        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(blurAmount / 10, forKey: kCIInputRadiusKey)

        guard let output = blurFilter.outputImage?.cropped(to: cropRect) else {
            return image
        }

        let context = CIContext(options: [:])
        return context.createCGImage(output, from: cropRect)
    }

    private static func createImageBackground(backgroundImage: PlatformImage?, size: CGSize) -> CGImage? {
        guard let backgroundImage,
              let cgImage = backgroundImage.cgImageValue else {
            return createSolidBackground(color: .gray, size: size)
        }

        let ciImage = CIImage(cgImage: cgImage)
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scale = max(scaleX, scaleY)
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let posX = (size.width - scaled.extent.width) / 2
        let posY = (size.height - scaled.extent.height) / 2
        let centered = scaled.transformed(by: CGAffineTransform(translationX: posX, y: posY))
        let cropped = centered.cropped(to: CGRect(origin: .zero, size: size))
        let context = CIContext(options: [:])
        return context.createCGImage(cropped, from: CGRect(origin: .zero, size: size))
    }

    // MARK: - Source Rendering

    private static func applyCornerRadius(_ image: CGImage, radius: Double) -> CGImage {
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
            roundedRect: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)),
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )

        context.addPath(path)
        context.clip()
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
        return context.makeImage()!
    }

    // MARK: - Device Frame

    private static func applyDeviceFrame(_ image: CGImage, frame: DeviceFrame, size: CGSize) -> CGImage {
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

        context.setFillColor(PlatformColor.clear.cgColor)
        context.fill(CGRect(origin: .zero, size: frameSize))

        context.setFillColor(deviceColor)
        let devicePath = CGPath(
            roundedRect: CGRect(origin: .zero, size: frameSize),
            cornerWidth: 20,
            cornerHeight: 20,
            transform: nil
        )
        context.addPath(devicePath)
        context.fillPath()

        context.draw(image, in: insetRect)

        context.setStrokeColor(PlatformColor.black.cgColor)
        context.setLineWidth(2)
        let screenPath = CGPath(
            roundedRect: insetRect,
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        context.addPath(screenPath)
        context.strokePath()

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
            let bezelSide: CGFloat = 20
            let bezelTopBottom: CGFloat = 30
            let frameWidth = imageSize.width + (bezelSide * 2)
            let frameHeight = imageSize.height + (bezelTopBottom * 2)
            let insetRect = CGRect(x: bezelSide, y: bezelTopBottom, width: imageSize.width, height: imageSize.height)
            return (CGSize(width: frameWidth, height: frameHeight), insetRect, PlatformColor.black.cgColor)

        case .macbook:
            let bezelSide: CGFloat = 15
            let bezelTop: CGFloat = 20
            let bezelBottom: CGFloat = 40
            let frameWidth = imageSize.width + (bezelSide * 2)
            let frameHeight = imageSize.height + bezelTop + bezelBottom
            let insetRect = CGRect(x: bezelSide, y: bezelTop, width: imageSize.width, height: imageSize.height)
            return (CGSize(width: frameWidth, height: frameHeight), insetRect, PlatformColor.darkGray.cgColor)

        case .none:
            return (imageSize, CGRect(origin: .zero, size: imageSize), PlatformColor.clear.cgColor)
        }
    }

    private static func addIPhoneDetails(to context: CGContext, frameSize: CGSize) {
        let notchWidth: CGFloat = 100
        let notchHeight: CGFloat = 20
        let notchRect = CGRect(x: (frameSize.width - notchWidth) / 2, y: 0, width: notchWidth, height: notchHeight)
        context.setFillColor(PlatformColor.black.cgColor)
        context.fill(notchRect)

        let indicatorRect = CGRect(
            x: (frameSize.width - 100) / 2,
            y: frameSize.height - 12,
            width: 100,
            height: 4
        )
        let indicatorPath = CGPath(roundedRect: indicatorRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        context.addPath(indicatorPath)
        context.fillPath()
    }

    private static func addMacBookDetails(to context: CGContext, frameSize: CGSize) {
        let lineY = frameSize.height - 15
        context.setStrokeColor(PlatformColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.beginPath()
        context.move(to: CGPoint(x: 30, y: lineY))
        context.addLine(to: CGPoint(x: frameSize.width - 30, y: lineY))
        context.strokePath()
    }

    // MARK: - Annotation Rendering

    private static func renderAnnotations(_ annotations: [Annotation], onto image: CGImage, canvasSize: CGSize) -> CGImage {
        let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.draw(image, in: CGRect(origin: .zero, size: canvasSize))
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        for annotation in annotations {
            draw(annotation: annotation, in: context, canvasSize: canvasSize)
        }

        return context.makeImage() ?? image
    }

    private static func draw(annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        switch annotation.type {
        case .text:
            drawText(annotation, in: context, canvasSize: canvasSize)
        case .arrow:
            drawArrow(annotation, in: context, canvasSize: canvasSize)
        case .rectangle:
            drawRectangle(annotation, in: context, canvasSize: canvasSize)
        case .ellipse:
            drawEllipse(annotation, in: context, canvasSize: canvasSize)
        case .highlight:
            drawBrushStroke(annotation, in: context, canvasSize: canvasSize, color: annotation.color.platformColor.withAlphaComponent(annotation.width))
        case .blur:
            drawBrushStroke(annotation, in: context, canvasSize: canvasSize, color: PlatformColor.black.withAlphaComponent(0.25))
        case .mosaic:
            drawBrushStroke(annotation, in: context, canvasSize: canvasSize, color: PlatformColor.black.withAlphaComponent(0.45))
        case .number:
            drawNumber(annotation, in: context, canvasSize: canvasSize)
        case .freehand:
            drawFreehand(annotation, in: context, canvasSize: canvasSize)
        }
    }

    private static func point(for normalizedPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
        CGPoint(
            x: normalizedPoint.x * canvasSize.width,
            y: canvasSize.height - (normalizedPoint.y * canvasSize.height)
        )
    }

    private static func rect(for annotation: Annotation, canvasSize: CGSize) -> CGRect? {
        guard let start = annotation.startPoint, let end = annotation.endPoint else { return nil }
        let startPoint = point(for: start, canvasSize: canvasSize)
        let endPoint = point(for: end, canvasSize: canvasSize)
        return CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }

    private static func drawText(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        let drawPoint = point(for: annotation.position, canvasSize: canvasSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: annotation.fontSize),
            .foregroundColor: annotation.color.platformColor
        ]
        let string = NSAttributedString(string: annotation.text, attributes: attributes)
        let textSize = string.size()

        drawAttributedString(
            string,
            at: CGPoint(x: drawPoint.x - textSize.width / 2, y: drawPoint.y - textSize.height / 2),
            in: context
        )
    }

    private static func drawArrow(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        guard let start = annotation.startPoint, let end = annotation.endPoint else { return }
        let startPoint = point(for: start, canvasSize: canvasSize)
        let endPoint = point(for: end, canvasSize: canvasSize)

        context.setStrokeColor(annotation.color.cgColor)
        context.setLineWidth(max(annotation.width, 1))
        context.setLineCap(.round)
        context.beginPath()
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()

        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength = max(annotation.width * 6, 12)
        let arrowAngle = CGFloat.pi / 6

        let point1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )

        context.beginPath()
        context.move(to: endPoint)
        context.addLine(to: point1)
        context.move(to: endPoint)
        context.addLine(to: point2)
        context.strokePath()
    }

    private static func drawRectangle(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        guard let rect = rect(for: annotation, canvasSize: canvasSize) else { return }
        context.setStrokeColor(annotation.color.cgColor)
        context.setLineWidth(max(annotation.width, 1))
        context.stroke(rect)
    }

    private static func drawEllipse(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        guard let rect = rect(for: annotation, canvasSize: canvasSize) else { return }
        context.setStrokeColor(annotation.color.cgColor)
        context.setLineWidth(max(annotation.width, 1))
        context.strokeEllipse(in: rect)
    }

    private static func drawFreehand(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        context.setStrokeColor(annotation.color.cgColor)
        context.setLineWidth(max(annotation.fontSize * 0.2, 2))
        context.setLineCap(.round)
        context.setLineJoin(.round)

        if let points = annotation.points, points.count > 1 {
            context.beginPath()
            context.move(to: point(for: points[0], canvasSize: canvasSize))
            for normalizedPoint in points.dropFirst() {
                context.addLine(to: point(for: normalizedPoint, canvasSize: canvasSize))
            }
            context.strokePath()
            return
        }

        guard let start = annotation.startPoint, let end = annotation.endPoint else { return }
        context.beginPath()
        context.move(to: point(for: start, canvasSize: canvasSize))
        context.addLine(to: point(for: end, canvasSize: canvasSize))
        context.strokePath()
    }

    private static func drawNumber(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize) {
        let center = point(for: annotation.position, canvasSize: canvasSize)
        let radius = max(annotation.fontSize * 0.8, 12)
        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        context.setFillColor(annotation.color.cgColor)
        context.fillEllipse(in: circleRect)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.boldSystemFont(ofSize: annotation.fontSize),
            .foregroundColor: PlatformColor.white
        ]
        let string = NSAttributedString(string: annotation.text.isEmpty ? "1" : annotation.text, attributes: attributes)
        let textSize = string.size()

        drawAttributedString(
            string,
            at: CGPoint(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2),
            in: context
        )
    }

    private static func drawBrushStroke(_ annotation: Annotation, in context: CGContext, canvasSize: CGSize, color: PlatformColor) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(max(annotation.fontSize, 1))
        context.setLineCap(.round)
        context.setLineJoin(.round)

        if let points = annotation.points, points.count > 1 {
            context.beginPath()
            context.move(to: point(for: points[0], canvasSize: canvasSize))
            for normalizedPoint in points.dropFirst() {
                context.addLine(to: point(for: normalizedPoint, canvasSize: canvasSize))
            }
            context.strokePath()
            return
        }

        guard let start = annotation.startPoint, let end = annotation.endPoint else { return }
        context.beginPath()
        context.move(to: point(for: start, canvasSize: canvasSize))
        context.addLine(to: point(for: end, canvasSize: canvasSize))
        context.strokePath()
    }

    // MARK: - Output

    private static func imageToData(_ image: CGImage, format: ImageFormat) throws -> Data {
        let platformImage = PlatformImage.from(cgImage: image)

        switch format {
        case .png:
            return platformImage.pngRepresentation() ?? Data()
        case .jpeg:
            return platformImage.jpegRepresentation(compressionQuality: 0.9) ?? Data()
        case .webp:
            return platformImage.pngRepresentation() ?? Data()
        }
    }

    private static func drawAttributedString(_ string: NSAttributedString, at point: CGPoint, in context: CGContext) {
        #if os(macOS)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        string.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
        #else
        UIGraphicsPushContext(context)
        string.draw(at: point)
        UIGraphicsPopContext()
        #endif
    }
}

private struct ExportLayout {
    let canvasSize: CGSize
    let imageRect: CGRect
}

private extension CodableColor {
    var platformColor: PlatformColor {
        PlatformColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var cgColor: CGColor {
        platformColor.cgColor
    }
}
