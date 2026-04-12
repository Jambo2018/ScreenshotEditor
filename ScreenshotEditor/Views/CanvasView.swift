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
                    previewCanvas(for: image)
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
    private func previewCanvas(for sourceImage: PlatformImage) -> some View {
        let previewImage = renderedPreviewImage(for: sourceImage) ?? sourceImage
        let previewSize = previewImage.pixelSize
        let previewAspectRatio = max(previewSize.width, 1) / max(previewSize.height, 1)
        let previewPadding: CGFloat = {
            #if os(iOS)
            return horizontalSizeClass == .compact ? 4 : 8
            #else
            return 24
            #endif
        }()

        ZStack {
            Image(platformImage: previewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onDrag {
                    itemProviderForImage(previewImage)
                }

            AnnotationLayerView(sourceImage: previewImage)
                .environmentObject(appState)
        }
        .aspectRatio(previewAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(previewPadding)
    }

    private func renderedPreviewImage(for sourceImage: PlatformImage) -> PlatformImage? {
        try? ImageExporter.renderImage(
            sourceImage: sourceImage,
            backgroundType: appState.backgroundType,
            gradientColors: appState.activeGradientColors,
            backgroundImage: appState.backgroundImage,
            blurAmount: appState.blurAmount,
            padding: appState.padding,
            cornerRadius: appState.cornerRadius,
            showShadow: false,
            showBorder: false,
            deviceFrame: appState.deviceFrame,
            aspectRatio: appState.exportAspectRatio,
            customAspectRatio: CGSize(
                width: appState.customAspectRatioWidth,
                height: appState.customAspectRatioHeight
            )
        )
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
        return 14
        #else
        return 20
        #endif
    }

    private var welcomePadding: CGFloat {
        #if os(iOS)
        return 20
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
        HStack(spacing: style == .large ? 8 : 10) {
            if appState.canCaptureScreen {
                captureButton
            }

            photoButtonIfNeeded
            importButton
        }
        .padding(style == .large ? 0 : 10)
        .background {
            if style == .compact {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var captureButton: some View {
        if style == .large {
            #if os(iOS)
            compactWelcomeButton(title: "截图", systemImage: "camera.viewfinder", prominent: true, action: appState.requestScreenCapture)
            #else
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.borderedProminent)
            #endif
        } else {
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var photoButtonIfNeeded: some View {
        #if os(iOS)
        if style == .large {
            compactWelcomeButton(title: "照片", systemImage: "photo.on.rectangle", prominent: false, action: appState.requestPhotoImport)
        } else {
            Button(action: { appState.requestPhotoImport() }) {
                Label("照片", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
        }
        #endif
    }

    @ViewBuilder
    private var importButton: some View {
        if style == .large {
            #if os(iOS)
            compactWelcomeButton(title: "导入", systemImage: "square.and.arrow.down", prominent: false, action: appState.requestImageImport)
            #else
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            #endif
        } else {
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func compactWelcomeButton(title: String, systemImage: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(prominent ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(prominent ? Color.accentColor : Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

struct EditingBottomBar: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let visibleTools: [AnnotationTool] = [.select, .rectangle, .text, .arrow, .mosaic, .freehand]

    var body: some View {
        HStack(spacing: barSpacing) {
            HStack(spacing: actionSpacing) {
                if appState.canCaptureScreen {
                    actionButton(
                        title: "截图",
                        systemImage: "camera.viewfinder",
                        prominent: false,
                        action: appState.requestScreenCapture
                    )
                }

                #if os(iOS)
                actionButton(
                    title: "照片",
                    systemImage: "photo.on.rectangle",
                    prominent: false,
                    action: appState.requestPhotoImport
                )
                #endif

                actionButton(
                    title: "导入",
                    systemImage: "square.and.arrow.down",
                    prominent: true,
                    action: appState.requestImageImport
                )
            }

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
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity)
        .background(
            Color(red: 0.75, green: 0.86, blue: 0.91).opacity(0.92)
        )
    }

    private var horizontalPadding: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 6 : 8
        #else
        return 20
        #endif
    }

    private var verticalPadding: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 4 : 5
        #else
        return 14
        #endif
    }

    private var actionSpacing: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 3 : 4
        #else
        return 10
        #endif
    }

    private var barSpacing: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 5 : 6
        #else
        return 14
        #endif
    }

    private var toolSpacing: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 2 : 3
        #else
        return 8
        #endif
    }

    private var separatorHeight: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 16 : 18
        #else
        return 34
        #endif
    }

    private func actionButton(title: String, systemImage: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    Image(systemName: systemImage)
                        .font(.system(size: actionIconSize, weight: .semibold))
                        .foregroundColor(prominent ? .white : Color.primary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous)
                                .fill(prominent ? Color.accentColor : Color.white.opacity(0.22))
                        )
                } else {
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
                            .fill(prominent ? Color.accentColor : Color.white.opacity(0.22))
                    )
                }
                #else
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
                        .fill(prominent ? Color.accentColor : Color.white.opacity(0.22))
                )
                #endif
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(0.18))
                )
        }
        .buttonStyle(.plain)
        .help(tool.title)
    }

    private var actionTitleSize: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 9 : 10
        #else
        return 16
        #endif
    }

    private var actionIconSize: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 9 : 10
        #else
        return 16
        #endif
    }

    private var buttonIconSpacing: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 2 : 3
        #else
        return 8
        #endif
    }

    private var actionHorizontalPadding: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 6 : 7
        #else
        return 18
        #endif
    }

    private var actionVerticalPadding: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 4 : 5
        #else
        return 12
        #endif
    }

    private var actionCornerRadius: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 6 : 7
        #else
        return 14
        #endif
    }

    private var toolIconSize: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 10 : 11
        #else
        return 15
        #endif
    }

    private var toolButtonSize: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 22 : 24
        #else
        return 38
        #endif
    }

    private var toolCornerRadius: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .compact ? 6 : 7
        #else
        return 12
        #endif
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
