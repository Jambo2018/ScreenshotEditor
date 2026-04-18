//
//  AnnotationPanelView.swift
//  ScreenshotEditor
//
//  Right-side panel for annotation tools
//

import SwiftUI

struct AnnotationPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var isToolPanelExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isToolPanelExpanded.toggle()
                }
            }) {
                HStack {
                    Label("标注设置", systemImage: "wand.and.rays")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isToolPanelExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, EditorSpacing.large)
                .padding(.vertical, EditorSpacing.medium)
            }
            .buttonStyle(.plain)

            if isToolPanelExpanded {
                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ToolSettingsSection()

                        Divider()

                        AnnotationsListSection()
                    }
                    .padding(EditorSpacing.large)
                }
            }
        }
        .frame(width: 220)
    }
}

// MARK: - Tool Settings Section

struct ToolSettingsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: EditorSpacing.large) {
            HStack {
                Text("当前工具")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label(appState.selectedAnnotationTool.title, systemImage: appState.selectedAnnotationTool.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            switch appState.selectedAnnotationTool {
            case .select:
                Text("选择工具：点击标注进行编辑或删除")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, EditorSpacing.small)

            case .text:
                TextSettingsView()

            case .arrow, .rectangle:
                ShapeSettingsView()

            case .mosaic, .freehand:
                BrushSettingsView()
            }
        }
    }
}

// MARK: - Text Settings View

struct TextSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: EditorSpacing.medium) {
            // Color picker
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                Text("文字颜色")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: EditorSpacing.xSmall) {
                    ForEach([Color.white, Color.black, Color.red, Color.green, Color.blue, Color.yellow], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(appState.currentTextColor == color ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                withAnimation {
                                    appState.currentTextColor = color
                                }
                            }
                    }
                }
            }

            // Font size slider
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                HStack {
                    Text("大小")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.currentTextSize))pt")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Slider(value: $appState.currentTextSize, in: 12...72, step: 2)
            }
        }
    }
}

// MARK: - Shape Settings View

struct ShapeSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: EditorSpacing.medium) {
            // Color picker
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                Text("颜色")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: EditorSpacing.xSmall) {
                    ForEach([Color.red, Color.green, Color.blue, Color.yellow, Color.white, Color.black], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(appState.currentShapeColor == color ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                withAnimation {
                                    appState.currentShapeColor = color
                                }
                            }
                    }
                }
            }

            // Stroke width slider
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                HStack {
                    Text("粗细")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.currentStrokeWidth))px")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Slider(value: $appState.currentStrokeWidth, in: 1...10, step: 1)
            }
        }
    }
}

// MARK: - Brush Settings View

struct BrushSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: EditorSpacing.medium) {
            if appState.selectedAnnotationTool == .freehand {
                VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                    Text("颜色")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: EditorSpacing.xSmall) {
                        ForEach([Color.red, Color.green, Color.blue, Color.yellow, Color.white, Color.black], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(appState.currentShapeColor == color ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    withAnimation {
                                        appState.currentShapeColor = color
                                    }
                                }
                        }
                    }
                }
            }

            // Brush size slider
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                HStack {
                    Text("大小")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.currentBrushSize))px")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Slider(value: $appState.currentBrushSize, in: 10...100, step: 5)
            }

            // Opacity slider
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                HStack {
                    Text("不透明度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.currentBrushOpacity * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Slider(value: $appState.currentBrushOpacity, in: 0.1...1.0, step: 0.1)
            }
        }
    }
}

// MARK: - Annotations List Section

struct AnnotationsListSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: EditorSpacing.small) {
            HStack {
                Text("标注列表")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !appState.annotations.isEmpty {
                    Button(action: {
                        withAnimation {
                            appState.annotations.removeAll()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }

            if appState.annotations.isEmpty {
                Text("暂无标注")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.vertical, EditorSpacing.small)
            } else {
                ForEach(appState.annotations) { annotation in
                    AnnotationRowView(annotation: annotation)
                        .onTapGesture {
                            appState.selectedAnnotationId = annotation.id
                        }
                }
            }
        }
    }
}

// MARK: - Annotation Row View

struct AnnotationRowView: View {
    let annotation: Annotation
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: EditorSpacing.small) {
            Image(systemName: annotation.type.icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(annotation.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Button(action: {
                withAnimation {
                    appState.annotations.removeAll { $0.id == annotation.id }
                }
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, EditorSpacing.small)
        .padding(.vertical, EditorSpacing.xxSmall)
        .background(
            RoundedRectangle(cornerRadius: EditorCornerRadius.tiny)
                .fill(appState.selectedAnnotationId == annotation.id ? Color.accentColor.opacity(0.2) : Color.clear)
        )
    }
}

#Preview {
    AnnotationPanelView()
        .environmentObject(AppState())
}
