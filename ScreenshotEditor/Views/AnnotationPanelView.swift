//
//  AnnotationPanelView.swift
//  ScreenshotEditor
//
//  Right-side panel for annotation tools
//

import SwiftUI

struct AnnotationPanelView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("标注工具")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tool picker
                    ToolPickerSection()

                    Divider()

                    // Tool-specific settings
                    ToolSettingsSection()

                    Divider()

                    // Annotations list
                    AnnotationsListSection()
                }
                .padding(12)
            }
        }
        .frame(width: 220)
    }
}

// MARK: - Tool Picker Section

struct ToolPickerSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("工具")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(AnnotationTool.allCases, id: \.self) { tool in
                    Button(action: {
                        withAnimation {
                            appState.selectedAnnotationTool = tool
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 14))
                            Text(tool.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(appState.selectedAnnotationTool == tool ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(appState.selectedAnnotationTool == tool ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Tool Settings Section

struct ToolSettingsSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置")
                .font(.caption)
                .foregroundColor(.secondary)

            switch appState.selectedAnnotationTool {
            case .select:
                Text("选择工具：点击标注进行编辑或删除")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)

            case .text:
                TextSettingsView()

            case .arrow, .rectangle:
                ShapeSettingsView()

            case .highlight, .blur:
                BrushSettingsView()
            }
        }
    }
}

// MARK: - Text Settings View

struct TextSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 10) {
            // Color picker
            VStack(alignment: .leading, spacing: 6) {
                Text("文字颜色")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
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
            VStack(alignment: .leading, spacing: 6) {
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
        VStack(spacing: 10) {
            // Color picker
            VStack(alignment: .leading, spacing: 6) {
                Text("颜色")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
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
            VStack(alignment: .leading, spacing: 6) {
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
        VStack(spacing: 10) {
            // Brush size slider
            VStack(alignment: .leading, spacing: 6) {
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
            VStack(alignment: .leading, spacing: 6) {
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
        VStack(alignment: .leading, spacing: 8) {
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
                    .padding(.vertical, 8)
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
        HStack(spacing: 8) {
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(appState.selectedAnnotationId == annotation.id ? Color.accentColor.opacity(0.2) : Color.clear)
        )
    }
}

#Preview {
    AnnotationPanelView()
        .environmentObject(AppState())
}
