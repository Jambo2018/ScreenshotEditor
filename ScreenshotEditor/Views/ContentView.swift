//
//  ContentView.swift
//  ScreenshotEditor
//
//  Main content view with platform-specific editor shells
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
        switch activeShell {
        case .desktop:
            DesktopEditorScreen()
        case .tablet:
            TabletEditorScreen(sceneState: sceneState)
        case .phone:
            PhoneEditorScreen(sceneState: sceneState)
        }
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

    private var sceneState: EditorSceneState {
        if appState.isExporting {
            return .exporting
        }

        return appState.hasScreenshot ? .editing : .empty
    }

    private var activeShell: EditorShell {
        #if os(macOS)
        return .desktop
        #else
        return horizontalSizeClass == .compact ? .phone : .tablet
        #endif
    }
}

private enum EditorShell {
    case desktop
    case tablet
    case phone
}

private enum EditorSceneState {
    case empty
    case editing
    case exporting

    var title: String {
        switch self {
        case .empty:
            return "开始"
        case .editing:
            return "编辑"
        case .exporting:
            return "导出中"
        }
    }

    var subtitle: String {
        switch self {
        case .empty:
            return "导入或截图后开始调整"
        case .editing:
            return "预览优先，工具常驻"
        case .exporting:
            return "请稍候，正在生成输出"
        }
    }
}

private enum WorkspaceDensity: Equatable {
    case phone
    case tablet

    var deviceClass: EditorDeviceClass {
        switch self {
        case .phone:
            return .phone
        case .tablet:
            return .tablet
        }
    }

    var cardPadding: CGFloat {
        deviceClass == .phone ? 9 : EditorSpacing.large
    }

    var cardSpacing: CGFloat {
        deviceClass == .phone ? 7 : EditorSpacing.medium
    }

    var titleSize: CGFloat {
        deviceClass == .phone ? 11 : 12
    }

    var subtitleSize: CGFloat {
        deviceClass == .phone ? 9 : 10
    }

    var swatchSize: CGFloat {
        deviceClass == .phone ? 22 : 28
    }

    var swatchColumns: Int {
        5
    }

    var gridSpacing: CGFloat {
        deviceClass == .phone ? 5 : 7
    }

    var menuWidth: CGFloat {
        deviceClass == .phone ? 80 : 92
    }
}

private struct EditorCanvasRegion: View {
    let shell: EditorShell

    var body: some View {
        CanvasView(showsEditingBottomBar: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(deviceClass.canvasPadding)
            .background(canvasBackground)
    }

    private var deviceClass: EditorDeviceClass {
        switch shell {
        case .desktop:
            return .desktop
        case .tablet:
            return .tablet
        case .phone:
            return .phone
        }
    }

    private var canvasBackground: Color {
        deviceClass == .desktop ? .editorPanelBackground : .editorBackground
    }
}

#if os(iOS)
private struct PhoneEditorScreen: View {
    let sceneState: EditorSceneState

    var body: some View {
        EditorCanvasRegion(shell: .phone)
            .background(Color.editorBackground.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                MobileTopInset(sceneState: sceneState, layout: .phone)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if sceneState != .empty {
                    MobileBottomDock(deviceClass: .phone)
                }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct TabletEditorScreen: View {
    let sceneState: EditorSceneState

    var body: some View {
        EditorCanvasRegion(shell: .tablet)
            .background(Color.editorBackground.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                MobileTopInset(sceneState: sceneState, layout: .tablet)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if sceneState != .empty {
                    MobileBottomDock(deviceClass: .tablet)
                }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct MobileTopInset: View {
    let sceneState: EditorSceneState
    let layout: MobileEditorLayout

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(sceneState: sceneState, layout: layout)
            Divider()
        }
        .background(Color.editorPanelBackground)
    }
}

private struct MobileBottomDock: View {
    let deviceClass: EditorDeviceClass

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if deviceClass == .phone {
                PhoneEditingWorkspace()
                Divider()
                EditingBottomBar(layoutStyle: .phone)
            } else {
                TabletEditingWorkspace()
                Divider()
                EditingBottomBar(layoutStyle: .tablet)
            }
        }
        .background(Color.editorPanelBackground)
    }
}

private enum MobileEditorLayout: Equatable {
    case phone
    case tablet

    var deviceClass: EditorDeviceClass {
        self == .phone ? .phone : .tablet
    }

    var titleSpacing: CGFloat {
        self == .phone ? EditorSpacing.micro : 3
    }

    var padding: EdgeInsets {
        deviceClass.topBarPadding
    }
}

private struct EditorTopBar: View {
    @EnvironmentObject var appState: AppState
    let sceneState: EditorSceneState
    let layout: MobileEditorLayout

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: layout.titleSpacing) {
                Text(sceneState.title)
                    .font(EditorTypography.topBarTitle(for: layout.deviceClass))
                Text(sceneState.subtitle)
                    .font(EditorTypography.topBarSubtitle(for: layout.deviceClass))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if appState.hasScreenshot {
                StatusChip(title: sceneState == .exporting ? "处理中" : "已载入")
            }

            Button(action: { appState.shareCurrent() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: layout.deviceClass == .phone ? 12 : 13, weight: .semibold))
                    .foregroundColor(appState.hasScreenshot && !appState.isExporting ? .primary : .secondary)
                    .frame(
                        width: layout.deviceClass.topBarButtonSide,
                        height: layout.deviceClass.topBarButtonSide
                    )
                    .background(
                        RoundedRectangle(cornerRadius: EditorCornerRadius.small, style: .continuous)
                            .fill(Color.secondary.opacity(EditorOpacity.subtleFill))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!appState.hasScreenshot || appState.isExporting)
            .accessibilityLabel("分享")
            .accessibilityIdentifier("editor.share")
        }
        .padding(layout.padding)
        .background(Color.editorPanelBackground.opacity(EditorOpacity.toolbar))
    }
}

private struct PhoneEditingWorkspace: View {
    var body: some View {
        MobileEditingWorkspacePanel(deviceClass: .phone)
    }
}

private struct TabletEditingWorkspace: View {
    var body: some View {
        MobileEditingWorkspacePanel(deviceClass: .tablet)
    }
}

private struct MobileEditingWorkspacePanel: View {
    let deviceClass: EditorDeviceClass

    var body: some View {
        ControlPanelView(layoutStyle: .inline)
            .padding(.horizontal, deviceClass == .phone ? 6 : 10)
            .padding(.vertical, deviceClass == .phone ? 4 : 6)
            .background(Color.editorPanelBackground)
    }
}
#endif

#if !os(iOS)
private struct PhoneEditorScreen: View {
    let sceneState: EditorSceneState

    var body: some View {
        EmptyView()
    }
}

private struct TabletEditorScreen: View {
    let sceneState: EditorSceneState

    var body: some View {
        EmptyView()
    }
}
#endif

#if os(macOS)
private struct DesktopEditorScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                DesktopContextBar()
                Divider()
                EditorCanvasRegion(shell: .desktop)

                if appState.hasScreenshot {
                    Divider()
                    EditingBottomBar(layoutStyle: .desktop)
                }
            }

            Divider()

            DesktopInspector()
                .frame(width: EditorDeviceClass.desktop.workspaceSectionWidth)
                .frame(maxHeight: .infinity)
                .background(Color.editorPanelBackground)
        }
        .background(Color.editorPanelBackground)
    }
}

private struct DesktopContextBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.hasScreenshot ? "Desktop Editor" : "Ready to import")
                    .font(EditorTypography.topBarTitle(for: .desktop))
                Text(contextSubtitle)
                    .font(EditorTypography.topBarSubtitle(for: .desktop))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            if appState.hasScreenshot {
                StatusChip(title: appState.isExporting ? "Exporting" : "Preview = Export")
            }
        }
        .padding(.horizontal, EditorDeviceClass.desktop.topBarPadding.leading)
        .padding(.vertical, EditorDeviceClass.desktop.topBarPadding.top)
        .background(Color.editorPanelBackground)
    }

    private var contextSubtitle: String {
        if let screenshot = appState.selectedScreenshot?.name, !screenshot.isEmpty {
            return screenshot
        }

        return "Capture or import a screenshot to start editing."
    }
}

private struct DesktopInspector: View {
    @State private var exportFormat: ImageFormat = .png

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DesktopInspectorStatusCard()
                DesktopInspectorCard {
                    BackgroundSection(layoutStyle: .sidebar)
                    Divider()
                    SlidersSection(layoutStyle: .sidebar)
                }
                DesktopInspectorCard {
                    AspectRatioSection(layoutStyle: .sidebar)
                    Divider()
                    ExportSection(exportFormat: $exportFormat, layoutStyle: .sidebar)
                }
                DesktopAnnotationInspectorCard()
            }
            .padding(EditorSpacing.xLarge)
        }
        .scrollIndicators(.hidden)
    }
}

private struct DesktopInspectorStatusCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        DesktopInspectorCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Workflow")
                    .font(.headline)

                LabeledContent("State") {
                    Text(appState.isExporting ? "Exporting" : (appState.hasScreenshot ? "Editing" : "Empty"))
                        .foregroundColor(.secondary)
                }

                LabeledContent("Background") {
                    Text(backgroundSummary)
                        .foregroundColor(.secondary)
                }

                LabeledContent("Padding") {
                    Text("\(Int(appState.padding))px")
                        .foregroundColor(.secondary)
                }

                if appState.hasScreenshot {
                    LabeledContent("Annotations") {
                        Text("\(appState.annotations.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var backgroundSummary: String {
        switch appState.backgroundType {
        case .color:
            return appState.selectedGradient.name
        case .none:
            return "None"
        case .image:
            return appState.backgroundImage == nil ? "Image" : "Custom image"
        }
    }
}

private struct DesktopAnnotationInspectorCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        DesktopInspectorCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Annotation")
                        .font(.headline)
                    Spacer()
                    Label(appState.selectedAnnotationTool.title, systemImage: appState.selectedAnnotationTool.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ToolSettingsSection()

                Divider()

                AnnotationsListSection()
            }
        }
    }
}

private struct DesktopInspectorCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(EditorSpacing.xLarge)
        .background(
            RoundedRectangle(cornerRadius: EditorCornerRadius.panel, style: .continuous)
                .fill(Color.secondary.opacity(EditorOpacity.panelFill))
        )
    }
}
#else
private struct DesktopEditorScreen: View {
    var body: some View {
        EmptyView()
    }
}
#endif

private struct WorkspaceCard<Content: View>: View {
    let title: String
    let subtitle: String
    let density: WorkspaceDensity
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: density.cardSpacing) {
            VStack(alignment: .leading, spacing: EditorSpacing.micro) {
                Text(title)
                    .font(EditorTypography.workspaceTitle(for: density.deviceClass))
                Text(subtitle)
                    .font(EditorTypography.workspaceSubtitle(for: density.deviceClass))
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding(density.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: EditorCornerRadius.panel, style: .continuous)
                .fill(Color.secondary.opacity(EditorOpacity.panelFill))
        )
    }
}

private struct CompactBackgroundPalette: View {
    @EnvironmentObject var appState: AppState
    let density: WorkspaceDensity

    var body: some View {
        VStack(alignment: .leading, spacing: density.gridSpacing) {
            Text(currentBackgroundLabel)
                .font(.system(size: density.subtitleSize, weight: .medium))
                .foregroundColor(.secondary)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(minimum: density.swatchSize, maximum: density.swatchSize + 6), spacing: density.gridSpacing),
                    count: density.swatchColumns
                ),
                spacing: density.gridSpacing
            ) {
                ForEach(GradientPreset.presets) { preset in
                    compactSwatch(
                        isSelected: appState.backgroundType == .color && appState.selectedGradient.id == preset.id,
                        accessibilityLabel: preset.name
                    ) {
                        LinearGradient(
                            colors: preset.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } action: {
                        selectPreset(preset)
                    }
                }

                compactSwatch(
                    isSelected: appState.backgroundType == .none,
                    accessibilityLabel: "无背景"
                ) {
                    CheckerboardView()
                } action: {
                    selectNoneBackground()
                }

                compactSwatch(
                    isSelected: appState.backgroundType == .image && appState.backgroundImage != nil,
                    accessibilityLabel: "背景图片"
                ) {
                    if let image = appState.backgroundImage {
                        Image(platformImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.18)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: density == .phone ? 10 : 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            )
                    }
                } action: {
                    appState.requestBackgroundImageImport()
                }
            }
        }
    }

    private var currentBackgroundLabel: String {
        switch appState.backgroundType {
        case .color:
            return "当前：\(appState.selectedGradient.name)"
        case .none:
            return "当前：None"
        case .image:
            return appState.backgroundImage == nil ? "当前：Image" : "当前：背景图片"
        }
    }

    @ViewBuilder
    private func compactSwatch<Content: View>(
        isSelected: Bool,
        accessibilityLabel: String,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            content()
                .frame(width: density.swatchSize, height: density.swatchSize)
                .clipShape(RoundedRectangle(cornerRadius: EditorCornerRadius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: EditorCornerRadius.small, style: .continuous)
                        .stroke(
                            isSelected ? Color.accentColor : Color.gray.opacity(EditorOpacity.swatchIdleStroke),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func selectPreset(_ preset: GradientPreset) {
        withAnimation(.easeInOut(duration: 0.15)) {
            appState.backgroundType = .color
            appState.selectedGradient = preset
            appState.backgroundImage = nil
            appState.useCustomGradient = false
        }
    }

    private func selectNoneBackground() {
        withAnimation(.easeInOut(duration: 0.15)) {
            appState.backgroundType = .none
            appState.backgroundImage = nil
            appState.useCustomGradient = false
        }
    }
}

private struct CompactAdjustmentsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            CompactInlineSliderRow(title: "Padding", value: $appState.padding, range: 0...200, unit: "px")
            CompactInlineSliderRow(title: "Rounded", value: $appState.cornerRadius, range: 0...40, unit: "px")
            CompactInlineSliderRow(title: "Blur", value: $appState.blurAmount, range: 0...100, unit: "%")
        }
    }
}

private struct CompactOutputSection: View {
    @EnvironmentObject var appState: AppState
    @Binding var exportFormat: ImageFormat
    let density: WorkspaceDensity
    @State private var isExporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: density.cardSpacing) {
            HStack(spacing: 6) {
                Text("比例")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, alignment: .leading)

                CompactMenuControl(title: appState.exportAspectRatio.rawValue, width: density.menuWidth) {
                    ForEach(ExportAspectRatio.allCases, id: \.self) { ratio in
                        Button(ratio.rawValue) {
                            appState.exportAspectRatio = ratio
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            if appState.exportAspectRatio == .custom {
                HStack(spacing: 5) {
                    CompactStepper(value: $appState.customAspectRatioWidth, title: "W")
                    CompactStepper(value: $appState.customAspectRatioHeight, title: "H")
                }
            }

            HStack(spacing: 6) {
                Text("格式")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, alignment: .leading)

                CompactMenuControl(title: exportFormat.rawValue, width: density == .phone ? 62 : 66) {
                    ForEach(ImageFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            exportFormat = format
                        }
                    }
                }

                CompactClipboardToggle()

                exportButton

                Spacer(minLength: 0)
            }
        }
    }

    private var exportButton: some View {
        Button(action: export) {
            HStack(spacing: 4) {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.55)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 10, weight: .semibold))
                }

                Text("导出")
                    .font(EditorTypography.compactLabel)
            }
            .foregroundColor(.white)
            .padding(.horizontal, density == .phone ? 7 : 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: EditorCornerRadius.compact, style: .continuous)
                    .fill(Color.accentColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(!appState.hasScreenshot || isExporting)
        .opacity((!appState.hasScreenshot || isExporting) ? 0.55 : 1)
        .accessibilityIdentifier("editor.export")
    }

    private func export() {
        isExporting = true
        appState.exportCurrent(format: exportFormat, copyToClipboard: appState.autoCopyToClipboard)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isExporting = false
        }
    }
}

private struct CompactClipboardToggle: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            appState.autoCopyToClipboard.toggle()
        } label: {
            Image(systemName: appState.autoCopyToClipboard ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                .font(EditorTypography.microLabel)
                .foregroundColor(appState.autoCopyToClipboard ? .accentColor : .secondary)
                .frame(width: 24, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: EditorCornerRadius.compact, style: .continuous)
                        .fill(
                            appState.autoCopyToClipboard
                                ? Color.accentColor.opacity(EditorOpacity.accentFill)
                                : Color.secondary.opacity(EditorOpacity.subtleFill)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appState.autoCopyToClipboard ? "关闭自动拷贝" : "开启自动拷贝")
    }
}

private struct StatusChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(EditorTypography.statusChip)
            .foregroundColor(.accentColor)
            .padding(.horizontal, EditorSpacing.small)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(EditorOpacity.accentFill))
            )
    }
}

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
        button.setAccessibilityIdentifier("editor.share")
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
