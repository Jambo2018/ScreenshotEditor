//
//  CanvasView.swift
//  ScreenshotEditor
//
//  Center preview canvas that mirrors export rendering
//

import SwiftUI
import UniformTypeIdentifiers

struct CanvasView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var showsEditingBottomBar: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let screenshot = appState.selectedScreenshot,
                   let image = screenshot.image {
                    previewCanvas(for: screenshot.id, sourceImage: image)
                } else {
                    WelcomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsEditingBottomBar && appState.hasScreenshot {
                Divider()

                EditingBottomBar()
                    .environmentObject(appState)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.editorBackground)
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    @ViewBuilder
    private func previewCanvas(for screenshotID: UUID, sourceImage: PlatformImage) -> some View {
        let previewPadding: CGFloat = {
            #if os(iOS)
            return (horizontalSizeClass == .compact ? EditorDeviceClass.phone : EditorDeviceClass.tablet).previewPadding
            #else
            return EditorDeviceClass.desktop.previewPadding
            #endif
        }()

        PreviewCanvasSurface(
            screenshotID: screenshotID,
            sourceImage: sourceImage,
            configuration: PreviewRenderConfiguration(
                backgroundType: appState.backgroundType,
                gradientColors: appState.activeGradientColors,
                backgroundImage: appState.backgroundImage,
                blurAmount: appState.blurAmount,
                padding: appState.padding,
                cornerRadius: appState.cornerRadius,
                deviceFrame: appState.deviceFrame,
                aspectRatio: appState.exportAspectRatio,
                customAspectRatio: CGSize(
                    width: appState.customAspectRatioWidth,
                    height: appState.customAspectRatioHeight
                )
            ),
            renderKey: previewRenderKey(for: screenshotID),
            previewPadding: previewPadding
        )
        .environmentObject(appState)
    }

    private func previewRenderKey(for screenshotID: UUID) -> String {
        let gradientSignature = appState.activeGradientColors.map(colorSignature).joined(separator: "|")
        return [
            screenshotID.uuidString,
            appState.backgroundType.rawValue,
            gradientSignature,
            imageSignature(appState.backgroundImage),
            formatValue(appState.blurAmount),
            formatValue(appState.padding),
            formatValue(appState.cornerRadius),
            appState.deviceFrame.rawValue,
            appState.exportAspectRatio.rawValue,
            formatValue(appState.customAspectRatioWidth),
            formatValue(appState.customAspectRatioHeight)
        ].joined(separator: "#")
    }

    private func colorSignature(_ color: Color) -> String {
        let cgColor = PlatformColor.from(color).cgColor
        let components = cgColor.components?.map { formatValue($0) }.joined(separator: ",") ?? "none"
        return "\(cgColor.colorSpace?.name as String? ?? "unknown"):\(components)"
    }

    private func imageSignature(_ image: PlatformImage?) -> String {
        guard let image else { return "nil" }
        return "\(ObjectIdentifier(image).hashValue)-\(Int(image.pixelSize.width))x\(Int(image.pixelSize.height))"
    }

    private func formatValue(_ value: CGFloat) -> String {
        String(format: "%.3f", value)
    }

    private func formatValue(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private func itemProviderForImage(_ image: PlatformImage) -> NSItemProvider {
        guard let pngData = image.pngRepresentation() else {
            return NSItemProvider()
        }

        return NSItemProvider(item: pngData as NSSecureCoding, typeIdentifier: UTType.png.identifier)
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
            if let error = error {
                DispatchQueue.main.async {
                    appState.errorMessage = "Failed to load image: \(error.localizedDescription)"
                }
                return
            }

            if let imageData = item as? Data,
               let image = PlatformImage(data: imageData) {
                appState.replaceCurrentImage(
                    image,
                    name: "Dropped Image \(Date().timeIntervalSince1970)"
                )
            } else if let url = item as? URL {
                appState.loadImage(from: url)
            }
        }
    }
}


private struct PreviewRenderConfiguration {
    let backgroundType: BackgroundType
    let gradientColors: [Color]
    let backgroundImage: PlatformImage?
    let blurAmount: Double
    let padding: Double
    let cornerRadius: Double
    let deviceFrame: DeviceFrame
    let aspectRatio: ExportAspectRatio
    let customAspectRatio: CGSize
}

private struct PreviewCanvasSurface: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.displayScale) private var displayScale

    let screenshotID: UUID
    let sourceImage: PlatformImage
    let configuration: PreviewRenderConfiguration
    let renderKey: String
    let previewPadding: CGFloat

    @State private var renderedPreviewImage: PlatformImage?

    private var displayedImage: PlatformImage {
        renderedPreviewImage ?? sourceImage
    }

    var body: some View {
        GeometryReader { proxy in
            let availableSize = availablePreviewSize(in: proxy.size)
            let previewSize = displayedImage.pixelSize
            let previewAspectRatio = max(previewSize.width, 1) / max(previewSize.height, 1)

            ZStack {
                Image(platformImage: displayedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onDrag {
                        itemProviderForImage(displayedImage)
                    }

                AnnotationLayerView(sourceImage: displayedImage)
                    .environmentObject(appState)
            }
            .aspectRatio(previewAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(previewPadding)
            .task(id: screenshotID) {
                renderedPreviewImage = sourceImage
            }
            .task(id: renderTaskKey(for: availableSize)) {
                await renderPreview(in: availableSize)
            }
        }
    }

    private func itemProviderForImage(_ image: PlatformImage) -> NSItemProvider {
        guard let pngData = image.pngRepresentation() else {
            return NSItemProvider()
        }

        return NSItemProvider(item: pngData as NSSecureCoding, typeIdentifier: UTType.png.identifier)
    }

    private func renderTaskKey(for availableSize: CGSize) -> String {
        let width = Int((availableSize.width * displayScale).rounded())
        let height = Int((availableSize.height * displayScale).rounded())
        return "\(renderKey)#\(width)x\(height)"
    }

    private func availablePreviewSize(in containerSize: CGSize) -> CGSize {
        CGSize(
            width: max(containerSize.width - (previewPadding * 2), 1),
            height: max(containerSize.height - (previewPadding * 2), 1)
        )
    }

    private func renderPreview(in availableSize: CGSize) async {
        let sourceImage = sourceImage
        let configuration = configuration
        let targetPixelSize = CGSize(
            width: max(availableSize.width * displayScale, 1),
            height: max(availableSize.height * displayScale, 1)
        )

        do {
            try await Task.sleep(nanoseconds: 60_000_000)
        } catch {
            return
        }

        if Task.isCancelled { return }

        let scaledInputs = scaledPreviewInputs(for: targetPixelSize)

        let rendered = await Task.detached(priority: .utility) {
            try? ImageExporter.renderImage(
                sourceImage: scaledInputs.sourceImage,
                backgroundType: configuration.backgroundType,
                gradientColors: configuration.gradientColors,
                backgroundImage: scaledInputs.backgroundImage,
                blurAmount: configuration.blurAmount,
                padding: configuration.padding * scaledInputs.scale,
                cornerRadius: configuration.cornerRadius * scaledInputs.scale,
                showShadow: false,
                showBorder: false,
                deviceFrame: configuration.deviceFrame,
                aspectRatio: configuration.aspectRatio,
                customAspectRatio: configuration.customAspectRatio
            )
        }.value

        if Task.isCancelled { return }

        renderedPreviewImage = rendered ?? sourceImage
    }

    private func scaledPreviewInputs(for targetPixelSize: CGSize) -> (sourceImage: PlatformImage, backgroundImage: PlatformImage?, scale: CGFloat) {
        let sourceSize = sourceImage.pixelSize
        let canvasSize = previewCanvasSize(for: sourceSize)
        let scale = min(
            targetPixelSize.width / max(canvasSize.width, 1),
            targetPixelSize.height / max(canvasSize.height, 1),
            1
        )

        guard scale < 0.98 else {
            return (sourceImage, configuration.backgroundImage, 1)
        }

        let resizedSource = sourceImage.resized(
            to: CGSize(
                width: max(sourceSize.width * scale, 1),
                height: max(sourceSize.height * scale, 1)
            )
        )

        let resizedBackground = configuration.backgroundImage?.resized(
            to: CGSize(
                width: max(canvasSize.width * scale, 1),
                height: max(canvasSize.height * scale, 1)
            )
        )

        return (resizedSource, resizedBackground, scale)
    }

    private func previewCanvasSize(for sourceSize: CGSize) -> CGSize {
        let minimumCanvasWidth = sourceSize.width + (configuration.padding * 2)
        let minimumCanvasHeight = sourceSize.height + (configuration.padding * 2)

        guard let targetRatio = resolvedAspectRatioValue() else {
            return CGSize(width: minimumCanvasWidth, height: minimumCanvasHeight)
        }

        let minimumRatio = minimumCanvasWidth / minimumCanvasHeight

        if targetRatio >= minimumRatio {
            let canvasHeight = minimumCanvasHeight
            return CGSize(width: canvasHeight * targetRatio, height: canvasHeight)
        } else {
            let canvasWidth = minimumCanvasWidth
            return CGSize(width: canvasWidth, height: canvasWidth / targetRatio)
        }
    }

    private func resolvedAspectRatioValue() -> CGFloat? {
        switch configuration.aspectRatio {
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
            guard configuration.customAspectRatio.width > 0, configuration.customAspectRatio.height > 0 else {
                return nil
            }
            return configuration.customAspectRatio.width / configuration.customAspectRatio.height
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        VStack(spacing: welcomeSpacing) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: heroIconSize))
                .foregroundColor(.secondary)

            Text("开始编辑截图")
                .font(welcomeTitleFont)
                .fontWeight(.semibold)

            Text("先去截图或导入图片，预览区显示的效果将与最终导出保持一致。")
                .font(welcomeBodyFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            #if os(iOS)
            Text("在 iPhone / iPad 上可从照片或文件导入；“截图”按钮会告诉你如何先用系统方式截屏。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            #endif

            CanvasActionBar(style: .large)
                .environmentObject(appState)

            Text("也支持直接拖拽图片到预览区")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(welcomePadding)
    }

    private var heroIconSize: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 44 : 52
        #else
        return 60
        #endif
    }

    private var welcomeTitleFont: Font {
        #if os(iOS)
        return .headline
        #else
        return .title2
        #endif
    }

    private var welcomeBodyFont: Font {
        #if os(iOS)
        return .footnote
        #else
        return .body
        #endif
    }

    private var welcomeSpacing: CGFloat {
        #if os(iOS)
        return EditorSpacing.xLarge
        #else
        return EditorSpacing.xxxLarge
        #endif
    }

    private var welcomePadding: CGFloat {
        #if os(iOS)
        return EditorSpacing.xxxLarge
        #else
        return 32
        #endif
    }
}

struct CanvasActionBar: View {
    enum Style {
        case compact
        case large
    }

    @EnvironmentObject var appState: AppState
    var style: Style = .compact

    var body: some View {
        HStack(spacing: style == .large ? EditorSpacing.small : EditorSpacing.medium) {
            if appState.canCaptureScreen {
                captureButton
            }

            photoButtonIfNeeded
            importButton
        }
        .padding(style == .large ? 0 : EditorSpacing.medium)
        .background {
            if style == .compact {
                RoundedRectangle(cornerRadius: EditorCornerRadius.xLarge)
                    .fill(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: EditorCornerRadius.xLarge))
    }

    @ViewBuilder
    private var captureButton: some View {
        if style == .large {
            #if os(iOS)
            compactWelcomeButton(title: "截图", systemImage: "camera.viewfinder", prominent: true, accessibilityIdentifier: "canvas.capture", action: appState.requestScreenCapture)
            #else
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("canvas.capture")
            #endif
        } else {
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("canvas.capture")
        }
    }

    @ViewBuilder
    private var photoButtonIfNeeded: some View {
        #if os(iOS)
        if style == .large {
            compactWelcomeButton(title: "照片", systemImage: "photo.on.rectangle", prominent: false, accessibilityIdentifier: "canvas.photo", action: appState.requestPhotoImport)
        } else {
            Button(action: { appState.requestPhotoImport() }) {
                Label("照片", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("canvas.photo")
        }
        #endif
    }

    @ViewBuilder
    private var importButton: some View {
        if style == .large {
            #if os(iOS)
            compactWelcomeButton(title: "导入", systemImage: "square.and.arrow.down", prominent: false, accessibilityIdentifier: "canvas.import", action: appState.requestImageImport)
            #else
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("canvas.import")
            #endif
        } else {
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("canvas.import")
        }
    }

    @ViewBuilder
    private func compactWelcomeButton(title: String, systemImage: String, prominent: Bool, accessibilityIdentifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(EditorTypography.welcomeButton)
                Text(title)
                    .font(EditorTypography.welcomeButton)
            }
            .foregroundColor(prominent ? .white : .primary)
            .padding(.horizontal, EditorSpacing.medium)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: EditorCornerRadius.medium, style: .continuous)
                    .fill(prominent ? Color.accentColor : Color.secondary.opacity(EditorOpacity.subtleFill))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct EditingBottomBar: View {
    enum LayoutStyle: Equatable {
        case desktop
        case tablet
        case phone
    }

    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let visibleTools: [AnnotationTool] = [.select, .rectangle, .text, .arrow, .mosaic, .freehand]
    var layoutStyle: LayoutStyle? = nil

    var body: some View {
        Group {
            switch resolvedLayoutStyle {
            case .phone:
                phoneBody
            case .tablet, .desktop:
                rowBody
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity)
        .background(barBackground)
    }

    private var rowBody: some View {
        HStack(spacing: barSpacing) {
            actionsRow

            Rectangle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 1, height: separatorHeight)

            HStack(spacing: toolSpacing) {
                ForEach(visibleTools, id: \.self) { tool in
                    toolButton(tool)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var phoneBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            actionsRow

            HStack(spacing: toolSpacing) {
                ForEach(visibleTools, id: \.self) { tool in
                    toolButton(tool)
                }
            }
        }
    }

    private var actionsRow: some View {
        HStack(spacing: actionSpacing) {
            if appState.canCaptureScreen {
                actionButton(
                    title: "截图",
                    systemImage: "camera.viewfinder",
                    prominent: false,
                    accessibilityIdentifier: "toolbar.capture",
                    action: appState.requestScreenCapture
                )
            }

            #if os(iOS)
            actionButton(
                title: "照片",
                systemImage: "photo.on.rectangle",
                prominent: false,
                accessibilityIdentifier: "toolbar.photo",
                action: appState.requestPhotoImport
            )
            #endif

            actionButton(
                title: "导入",
                systemImage: "square.and.arrow.down",
                prominent: true,
                accessibilityIdentifier: "toolbar.import",
                action: appState.requestImageImport
            )

            Spacer(minLength: 0)
        }
    }

    private var resolvedLayoutStyle: LayoutStyle {
        if let layoutStyle {
            return layoutStyle
        }

        #if os(iOS)
        return horizontalSizeClass == .compact ? .phone : .tablet
        #else
        return .desktop
        #endif
    }

    private var deviceClass: EditorDeviceClass {
        switch resolvedLayoutStyle {
        case .phone:
            return .phone
        case .tablet:
            return .tablet
        case .desktop:
            return .desktop
        }
    }

    private var barBackground: Color {
        Color(red: 0.75, green: 0.86, blue: 0.91).opacity(resolvedLayoutStyle == .desktop ? 0.92 : 0.96)
    }

    private var horizontalPadding: CGFloat {
        deviceClass.bottomBarHorizontalPadding
    }

    private var verticalPadding: CGFloat {
        deviceClass.bottomBarVerticalPadding
    }

    private var actionSpacing: CGFloat {
        deviceClass.bottomBarActionSpacing
    }

    private var barSpacing: CGFloat {
        deviceClass.bottomBarSpacing
    }

    private var toolSpacing: CGFloat {
        deviceClass.bottomBarToolSpacing
    }

    private var separatorHeight: CGFloat {
        deviceClass.bottomBarSeparatorHeight
    }

    private func actionButton(title: String, systemImage: String, prominent: Bool, accessibilityIdentifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: buttonIconSpacing) {
                Image(systemName: systemImage)
                    .font(.system(size: actionIconSize, weight: .semibold))
                Text(title)
                    .font(.system(size: actionTitleSize, weight: .semibold))
            }
            .foregroundColor(prominent ? .white : Color.primary)
            .padding(.horizontal, actionHorizontalPadding)
            .padding(.vertical, actionVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous)
                    .fill(prominent ? Color.accentColor : Color.white.opacity(EditorOpacity.swatchIdleStroke))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func toolButton(_ tool: AnnotationTool) -> some View {
        let isSelected = appState.selectedAnnotationTool == tool

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedAnnotationTool = tool
            }
        }) {
            Image(systemName: tool.icon)
                .font(.system(size: toolIconSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.primary.opacity(0.82))
                .frame(width: toolButtonSize, height: toolButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: toolCornerRadius, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(EditorOpacity.selectedFill))
                )
        }
        .buttonStyle(.plain)
        .help(tool.title)
        .accessibilityLabel(tool.title)
        .accessibilityIdentifier("tool.\(tool.rawValue)")
    }

    private var toolIconSize: CGFloat {
        deviceClass.toolIconSize
    }

    private var toolButtonSize: CGFloat {
        deviceClass.toolButtonSize
    }

    private var toolCornerRadius: CGFloat {
        deviceClass.toolCornerRadius
    }

    private var actionTitleSize: CGFloat {
        deviceClass.actionTitleSize
    }

    private var actionIconSize: CGFloat {
        deviceClass.actionIconSize
    }

    private var buttonIconSpacing: CGFloat {
        deviceClass.buttonIconSpacing
    }

    private var actionHorizontalPadding: CGFloat {
        deviceClass.actionHorizontalPadding
    }

    private var actionVerticalPadding: CGFloat {
        deviceClass.actionVerticalPadding
    }

    private var actionCornerRadius: CGFloat {
        deviceClass.actionCornerRadius
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
