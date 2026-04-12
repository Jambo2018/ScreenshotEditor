//
//  CanvasView.swift
//  ScreenshotEditor
//
//  Center preview canvas that mirrors export rendering
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CanvasView: View {
    @EnvironmentObject var appState: AppState

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

            if appState.hasScreenshot {
                Divider()

                EditingBottomBar()
                    .environmentObject(appState)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    @ViewBuilder
    private func previewCanvas(for sourceImage: NSImage) -> some View {
        let previewImage = renderedPreviewImage(for: sourceImage) ?? sourceImage
        let previewAspectRatio = max(previewImage.size.width, 1) / max(previewImage.size.height, 1)

        ZStack {
            Image(nsImage: previewImage)
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
        .padding(24)
    }

    private func renderedPreviewImage(for sourceImage: NSImage) -> NSImage? {
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

    private func itemProviderForImage(_ image: NSImage) -> NSItemProvider {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return NSItemProvider()
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
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
               let nsImage = NSImage(data: imageData) {
                appState.replaceCurrentImage(
                    nsImage,
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

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("开始编辑截图")
                .font(.title2)
                .fontWeight(.semibold)

            Text("先去截图或导入图片，预览区显示的效果将与最终导出保持一致。")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            CanvasActionBar(style: .large)
                .environmentObject(appState)

            Text("也支持直接拖拽图片到预览区")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
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
        HStack(spacing: 10) {
            if appState.canCaptureScreen {
                captureButton
            }

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
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button(action: { appState.requestScreenCapture() }) {
                Label("截图", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var importButton: some View {
        if style == .large {
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
        } else {
            Button(action: { appState.requestImageImport() }) {
                Label("导入图片", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct EditingBottomBar: View {
    @EnvironmentObject var appState: AppState
    private let visibleTools: [AnnotationTool] = [.select, .rectangle, .text, .arrow, .mosaic, .freehand]

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                if appState.canCaptureScreen {
                    actionButton(
                        title: "截图",
                        systemImage: "camera.viewfinder",
                        prominent: false,
                        action: appState.requestScreenCapture
                    )
                }

                actionButton(
                    title: "导入图片",
                    systemImage: "square.and.arrow.down",
                    prominent: true,
                    action: appState.requestImageImport
                )
            }

            Rectangle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 1, height: 34)

            HStack(spacing: 8) {
                ForEach(visibleTools, id: \.self) { tool in
                    toolButton(tool)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            Color(red: 0.75, green: 0.86, blue: 0.91).opacity(0.92)
        )
    }

    private func actionButton(title: String, systemImage: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(prominent ? .white : Color.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(prominent ? Color.accentColor : Color.white.opacity(0.22))
            )
        }
        .buttonStyle(.plain)
    }

    private func toolButton(_ tool: AnnotationTool) -> some View {
        let isSelected = appState.selectedAnnotationTool == tool

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedAnnotationTool = tool
            }
        }) {
            Image(systemName: tool.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.primary.opacity(0.82))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(0.18))
                )
        }
        .buttonStyle(.plain)
        .help(tool.title)
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
