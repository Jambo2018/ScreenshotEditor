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
        Group {
            if let screenshot = appState.selectedScreenshot,
               let image = screenshot.image {
                previewCanvas(for: image)
            } else {
                WelcomeView()
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
            showShadow: appState.showShadow,
            showBorder: appState.showBorder,
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

            HStack(spacing: 12) {
                Button(action: { appState.startScreenCapture() }) {
                    Label("去截图", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.borderedProminent)

                Button(action: { appState.importScreenshot() }) {
                    Label("导入图片", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }

            Text("也支持直接拖拽图片到预览区")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    CanvasView()
        .environmentObject(AppState())
}
