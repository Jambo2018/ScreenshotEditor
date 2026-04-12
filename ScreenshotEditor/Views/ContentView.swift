//
//  ContentView.swift
//  ScreenshotEditor
//
//  Main content view with three-column layout
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showErrorSheet: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        rootContent
        .onChange(of: appState.errorMessage) { _, newValue in
            showErrorSheet = newValue != nil
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .automatic) {
                ToolbarShareButton(appState: appState)
            }
            #endif
        }
        .fileImporter(
            isPresented: $appState.isImportPickerPresented,
            allowedContentTypes: [.png, .jpeg, .heic, .tiff, .image],
            allowsMultipleSelection: false,
            onCompletion: handleImageImport
        )
        .fileImporter(
            isPresented: $appState.isBackgroundImagePickerPresented,
            allowedContentTypes: [.png, .jpeg, .heic, .tiff, .image],
            allowsMultipleSelection: false,
            onCompletion: handleBackgroundImageImport
        )
        .photosPicker(
            isPresented: $appState.isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .sheet(isPresented: $showErrorSheet) {
            ErrorView(message: $appState.errorMessage)
        }
        .sheet(item: $appState.shareSheetFile) { item in
            PlatformShareSheet(items: [item.url])
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
        #if os(iOS)
        .sheet(isPresented: $appState.isCaptureGuidePresented) {
            CaptureGuideSheet()
        }
        #endif
    }

    @ViewBuilder
    private var rootContent: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            CanvasView()

            Divider()

            VStack(spacing: 0) {
                ControlPanelView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 288)
        }
        #else
        CanvasView(showsEditingBottomBar: false)
            .safeAreaInset(edge: .top, spacing: 0) {
                MobileTopBar()
                    .environmentObject(appState)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if appState.hasScreenshot {
                    VStack(spacing: 0) {
                        Divider()

                        ControlPanelView(layoutStyle: .inline)
                            .frame(height: mobileControlPanelHeight)
                            .background(Color.editorPanelBackground)

                        Divider()

                        EditingBottomBar()
                            .environmentObject(appState)
                    }
                    .background(Color.editorPanelBackground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.editorPanelBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #endif
    }

    private var mobileControlPanelHeight: CGFloat {
        horizontalSizeClass == .compact ? 130 : 138
    }

    private func handleImageImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            appState.loadImage(from: url)
        case .failure(let error):
            appState.errorMessage = "Failed to import image: \(error.localizedDescription)"
        }
    }

    private func handleBackgroundImageImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            appState.loadBackgroundImage(from: url)
        case .failure(let error):
            appState.errorMessage = "Failed to import background image: \(error.localizedDescription)"
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = PlatformImage(data: data) else {
                    await MainActor.run {
                        appState.errorMessage = "Failed to load the selected photo"
                        selectedPhotoItem = nil
                    }
                    return
                }

                await MainActor.run {
                    appState.replaceCurrentImage(
                        image,
                        name: "Photo-\(Date().formatted(.dateTime.hour().minute().second()))"
                    )
                    selectedPhotoItem = nil
                }
            } catch {
                await MainActor.run {
                    appState.errorMessage = "Failed to import photo: \(error.localizedDescription)"
                    selectedPhotoItem = nil
                }
            }
        }
    }
}

#if os(iOS)
private struct MobileTopBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            Button(action: { appState.shareCurrent() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appState.hasScreenshot && !appState.isExporting ? .primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!appState.hasScreenshot || appState.isExporting)
            .accessibilityLabel("分享")
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .background(Color.editorPanelBackground.opacity(0.98))
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(AppState())
}

#if os(macOS)
struct ToolbarShareButton: NSViewRepresentable {
    @ObservedObject var appState: AppState

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(
            systemSymbolName: "square.and.arrow.up",
            accessibilityDescription: "Share"
        )
        button.imagePosition = .imageOnly
        button.controlSize = .large
        button.contentTintColor = .labelColor
        button.target = context.coordinator
        button.action = #selector(Coordinator.didPressShare(_:))
        button.toolTip = "Share to other apps"
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.appState = appState
        nsView.isEnabled = appState.hasScreenshot && !appState.isExporting
    }

    final class Coordinator: NSObject {
        var appState: AppState

        init(appState: AppState) {
            self.appState = appState
        }

        @objc func didPressShare(_ sender: NSButton) {
            appState.shareCurrent(from: sender)
        }
    }
}
#endif

#if os(iOS)
private struct CaptureGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Label("iPhone / iPad 不支持应用内系统级截屏。", systemImage: "info.circle")
                    .font(.headline)

                Text("请先使用系统方式截图，然后回到应用继续编辑：")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("1. 使用设备按键完成系统截图")
                    Text("2. 回到本应用")
                    Text("3. 通过“照片”或“导入图片”把截图带进来")
                }
                .font(.body)

                Spacer()
            }
            .padding(20)
            .navigationTitle("截图说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("知道了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlatformShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct PlatformShareSheet: View {
    let items: [Any]

    var body: some View {
        Text("Share sheet is handled from the toolbar on macOS.")
            .padding()
    }
}
#endif
