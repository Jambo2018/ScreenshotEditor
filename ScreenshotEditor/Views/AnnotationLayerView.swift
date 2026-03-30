//
//  AnnotationLayerView.swift
//  ScreenshotEditor
//
//  Annotation layer for rendering and interacting with annotations
//

import SwiftUI

struct AnnotationLayerView: View {
    @EnvironmentObject var appState: AppState
    let sourceImage: NSImage

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Render all annotations
                ForEach(appState.annotations) { annotation in
                    AnnotationRenderer(annotation: annotation, imageSize: sourceImage.size, canvasSize: geometry.size)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleAnnotationTap(annotation: annotation)
                        }
                        .gesture(annotationDragGesture(annotation: annotation, canvasSize: geometry.size))
                }

                // Drawing layer for new annotations
                if appState.selectedAnnotationTool != AnnotationTool.select {
                    DrawingCanvas(
                        tool: appState.selectedAnnotationTool,
                        onStart: { location in
                            startDrawing(at: location, in: geometry.size)
                        },
                        onMove: { location in
                            continueDrawing(at: location, in: geometry.size)
                        },
                        onEnd: { location in
                            finishDrawing(at: location, in: geometry.size)
                        }
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Annotation Tap Handling

    private func handleAnnotationTap(annotation: Annotation) {
        if appState.selectedAnnotationTool == AnnotationTool.select {
            appState.selectedAnnotationId = annotation.id
        }
    }

    // MARK: - Drag Gesture

    private func annotationDragGesture(annotation: Annotation, canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard appState.selectedAnnotationTool == AnnotationTool.select,
                      appState.selectedAnnotationId == annotation.id else { return }

                let newPosition = value.location
                updateAnnotationPosition(id: annotation.id, to: newPosition, canvasSize: canvasSize)
            }
    }

    private func updateAnnotationPosition(id: UUID, to location: CGPoint, canvasSize: CGSize) {
        guard let index = appState.annotations.firstIndex(where: { $0.id == id }) else { return }

        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        appState.annotations[index].position = CGPoint(x: normalizedX, y: normalizedY)
    }

    // MARK: - Drawing Methods

    private func startDrawing(at location: CGPoint, in canvasSize: CGSize) {
        switch appState.selectedAnnotationTool {
        case AnnotationTool.text:
            addTextAnnotation(at: location, canvasSize: canvasSize)
        case AnnotationTool.arrow, AnnotationTool.rectangle:
            startShapeDrawing(at: location, canvasSize: canvasSize)
        case AnnotationTool.highlight, AnnotationTool.blur:
            startBrushDrawing(at: location, canvasSize: canvasSize)
        default:
            break
        }
    }

    private func continueDrawing(at location: CGPoint, in canvasSize: CGSize) {
        switch appState.selectedAnnotationTool {
        case AnnotationTool.arrow, AnnotationTool.rectangle:
            updateShapeDrawing(at: location, canvasSize: canvasSize)
        case AnnotationTool.highlight, AnnotationTool.blur, AnnotationTool.mosaic:
            updateBrushDrawing(at: location, canvasSize: canvasSize)
        default:
            break
        }
    }

    private func finishDrawing(at location: CGPoint, in canvasSize: CGSize) {
        switch appState.selectedAnnotationTool {
        case AnnotationTool.arrow, AnnotationTool.rectangle:
            completeShapeDrawing(at: location, canvasSize: canvasSize)
        case AnnotationTool.highlight, AnnotationTool.blur, AnnotationTool.mosaic:
            completeBrushDrawing(at: location, canvasSize: canvasSize)
        default:
            break
        }
    }

    // MARK: - Text Annotation

    private func addTextAnnotation(at location: CGPoint, canvasSize: CGSize) {
        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        let annotation = Annotation(
            id: UUID(),
            type: AnnotationType.text,
            text: "标注文字",
            position: CGPoint(x: normalizedX, y: normalizedY),
            fontSize: appState.currentTextSize,
            color: CodableColor(color: appState.currentTextColor),
            width: 0,
            startPoint: nil as CGPoint?,
            endPoint: nil as CGPoint?,
            size: nil as CGSize?
        )

        appState.annotations.append(annotation)
        appState.selectedAnnotationId = annotation.id
        appState.selectedAnnotationTool = AnnotationTool.select
    }

    // MARK: - Shape Drawing (Arrow, Rectangle)

    private func startShapeDrawing(at location: CGPoint, canvasSize: CGSize) {
        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        let type: AnnotationType = (appState.selectedAnnotationTool == AnnotationTool.arrow) ? AnnotationType.arrow : AnnotationType.rectangle

        let annotation = Annotation(
            id: UUID(),
            type: type,
            text: "",
            position: CGPoint.zero,
            fontSize: 0,
            color: CodableColor(color: appState.currentShapeColor),
            width: appState.currentStrokeWidth,
            startPoint: CGPoint(x: normalizedX, y: normalizedY),
            endPoint: CGPoint(x: normalizedX, y: normalizedY),
            size: nil as CGSize?
        )

        appState.annotations.append(annotation)
        appState.selectedAnnotationId = annotation.id
    }

    private func updateShapeDrawing(at location: CGPoint, canvasSize: CGSize) {
        guard let id = appState.selectedAnnotationId,
              let index = appState.annotations.firstIndex(where: { $0.id == id }) else { return }

        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        appState.annotations[index].endPoint = CGPoint(x: normalizedX, y: normalizedY)
    }

    private func completeShapeDrawing(at location: CGPoint, canvasSize: CGSize) {
        updateShapeDrawing(at: location, canvasSize: canvasSize)
        appState.selectedAnnotationTool = AnnotationTool.select
    }

    // MARK: - Brush Drawing (Highlight, Blur)

    private func startBrushDrawing(at location: CGPoint, canvasSize: CGSize) {
        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        let type: AnnotationType
        let color: Color
        if appState.selectedAnnotationTool == AnnotationTool.highlight {
            type = AnnotationType.highlight
            color = Color.yellow
        } else if appState.selectedAnnotationTool == AnnotationTool.blur {
            type = AnnotationType.blur
            color = Color.black
        } else {
            type = AnnotationType.mosaic
            color = Color.clear
        }

        let annotation = Annotation(
            id: UUID(),
            type: type,
            text: "",
            position: CGPoint(x: normalizedX, y: normalizedY),
            fontSize: appState.currentBrushSize,
            color: CodableColor(color: color),
            width: appState.currentBrushOpacity,
            startPoint: CGPoint(x: normalizedX, y: normalizedY),
            endPoint: nil as CGPoint?,
            size: nil as CGSize?
        )

        appState.annotations.append(annotation)
        appState.selectedAnnotationId = annotation.id
    }

    private func updateBrushDrawing(at location: CGPoint, canvasSize: CGSize) {
        guard let id = appState.selectedAnnotationId,
              let index = appState.annotations.firstIndex(where: { $0.id == id }) else { return }

        let normalizedX = location.x / canvasSize.width
        let normalizedY = location.y / canvasSize.height

        if appState.annotations[index].endPoint == nil {
            appState.annotations[index].endPoint = CGPoint(x: normalizedX, y: normalizedY)
        } else {
            appState.annotations[index].endPoint = CGPoint(x: normalizedX, y: normalizedY)
        }
    }

    private func completeBrushDrawing(at location: CGPoint, canvasSize: CGSize) {
        updateBrushDrawing(at: location, canvasSize: canvasSize)
        appState.selectedAnnotationTool = AnnotationTool.select
    }
}

// MARK: - Annotation Renderer

struct AnnotationRenderer: View {
    let annotation: Annotation
    let imageSize: CGSize
    let canvasSize: CGSize

    var body: some View {
        switch annotation.type {
        case AnnotationType.text:
            TextAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.arrow:
            ArrowAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.rectangle:
            RectangleAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.ellipse:
            EllipseAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.highlight:
            HighlightAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.blur:
            BlurAnnotationView(annotation: annotation, canvasSize: canvasSize)
        case AnnotationType.mosaic:
            MosaicAnnotationView(annotation: annotation, canvasSize: canvasSize)
        }
    }
}

// MARK: - Text Annotation View

struct TextAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        Text(annotation.text)
            .font(.system(size: annotation.fontSize))
            .foregroundColor(annotation.color.color)
            .position(
                x: annotation.position.x * canvasSize.width,
                y: annotation.position.y * canvasSize.height
            )
    }
}

// MARK: - Arrow Annotation View

struct ArrowAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let startPoint = CGPoint(x: start.x * canvasSize.width, y: start.y * canvasSize.height)
            let endPoint = CGPoint(x: end.x * canvasSize.width, y: end.y * canvasSize.height)

            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)

                // Arrow head
                let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
                let arrowLength: CGFloat = 15
                let arrowAngle: CGFloat = .pi / 6

                let arrowPoint1 = CGPoint(
                    x: endPoint.x - arrowLength * cos(angle - arrowAngle),
                    y: endPoint.y - arrowLength * sin(angle - arrowAngle)
                )

                let arrowPoint2 = CGPoint(
                    x: endPoint.x - arrowLength * cos(angle + arrowAngle),
                    y: endPoint.y - arrowLength * sin(angle + arrowAngle)
                )

                path.addLine(to: arrowPoint1)
                path.move(to: endPoint)
                path.addLine(to: arrowPoint2)
            }
            .stroke(annotation.color.color, lineWidth: annotation.width)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Rectangle Annotation View

struct RectangleAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let rect = CGRect(
                x: min(start.x, end.x) * canvasSize.width,
                y: min(start.y, end.y) * canvasSize.height,
                width: abs(end.x - start.x) * canvasSize.width,
                height: abs(end.y - start.y) * canvasSize.height
            )

            RoundedRectangle(cornerRadius: 4)
                .stroke(annotation.color.color, lineWidth: annotation.width)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Ellipse Annotation View

struct EllipseAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let rect = CGRect(
                x: min(start.x, end.x) * canvasSize.width,
                y: min(start.y, end.y) * canvasSize.height,
                width: abs(end.x - start.x) * canvasSize.width,
                height: abs(end.y - start.y) * canvasSize.height
            )

            Ellipse()
                .stroke(annotation.color.color, lineWidth: annotation.width)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Highlight Annotation View

struct HighlightAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let startPoint = CGPoint(x: start.x * canvasSize.width, y: start.y * canvasSize.height)
            let endPoint = CGPoint(x: end.x * canvasSize.width, y: end.y * canvasSize.height)

            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(annotation.color.color.opacity(annotation.width), lineWidth: annotation.fontSize)
            .blur(radius: 1)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Blur Annotation View

struct BlurAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let startPoint = CGPoint(x: start.x * canvasSize.width, y: start.y * canvasSize.height)
            let endPoint = CGPoint(x: end.x * canvasSize.width, y: end.y * canvasSize.height)

            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black.opacity(0.3), lineWidth: annotation.fontSize)
            .blur(radius: 5)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Mosaic Annotation View

struct MosaicAnnotationView: View {
    let annotation: Annotation
    let canvasSize: CGSize

    var body: some View {
        if let start = annotation.startPoint, let end = annotation.endPoint {
            let startPoint = CGPoint(x: start.x * canvasSize.width, y: start.y * canvasSize.height)
            let endPoint = CGPoint(x: end.x * canvasSize.width, y: end.y * canvasSize.height)

            // Draw mosaic effect as a thick pixelated line
            Path { path in
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black.opacity(0.5), lineWidth: annotation.fontSize)
            .blur(radius: 2)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Drawing Canvas

struct DrawingCanvas: View {
    let tool: AnnotationTool
    let onStart: (CGPoint) -> Void
    let onMove: (CGPoint) -> Void
    let onEnd: (CGPoint) -> Void

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if tool != AnnotationTool.select {
                                let location = value.location
                                if value.predictedEndLocation != value.location {
                                    onMove(location)
                                } else {
                                    onStart(location)
                                }
                            }
                        }
                        .onEnded { value in
                            if tool != AnnotationTool.select {
                                onEnd(value.location)
                            }
                        }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
