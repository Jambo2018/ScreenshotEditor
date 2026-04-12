//
//  ControlPanelView.swift
//  ScreenshotEditor
//
//  Right panel with background and export controls
//

import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var exportFormat: ImageFormat = .png

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Background Section
                BackgroundSection()

                Divider()

                // Sliders Section
                SlidersSection()

                Divider()

                AspectRatioSection()

                Divider()

                // Export Section
                ExportSection(exportFormat: $exportFormat)
            }
            .padding(16)
        }
    }
}

// MARK: - Background Section

struct BackgroundSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background")
                .font(.headline)

            // Background type picker
            Picker("Type", selection: $appState.backgroundType) {
                ForEach(BackgroundType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Unified color background (single color or gradient)
            if appState.backgroundType == .color {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(GradientPreset.presets) { preset in
                            Button(action: {
                                withAnimation {
                                    appState.selectedGradient = preset
                                    appState.useCustomGradient = false
                                }
                            }) {
                                gradientCard(
                                    title: preset.name,
                                    colors: preset.colors,
                                    isSelected: !appState.useCustomGradient && appState.selectedGradient.id == preset.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Custom")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: {
                            withAnimation {
                                appState.useCustomGradient = true
                            }
                        }) {
                            gradientCard(
                                title: "Custom",
                                colors: appState.activeGradientColors,
                                isSelected: appState.useCustomGradient
                            )
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 12) {
                            ColorPicker("Color A", selection: customGradientStartBinding)
                            if appState.useSecondCustomGradientColor {
                                ColorPicker("Color B", selection: customGradientEndBinding)
                            }
                        }
                        .font(.caption)

                        Toggle("Second Color (Gradient)", isOn: secondColorBinding)
                            .font(.caption)
                    }
                }
            }

            // Image picker (for custom image mode)
            if appState.backgroundType == .image {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Background")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: selectBackgroundImage) {
                        HStack {
                            Image(systemName: "photo")
                            Text(appState.backgroundImage != nil ? "Change Image..." : "Choose Image...")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if let backgroundImage = appState.backgroundImage {
                        HStack {
                            Image(nsImage: backgroundImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(6)
                                .clipped()

                            Button(action: clearBackgroundImage) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
    }

    private func selectBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a background image"

        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let image = NSImage(contentsOf: url) else { return }
            DispatchQueue.main.async {
                withAnimation {
                    appState.backgroundImage = image
                }
            }
        }
    }

    private func clearBackgroundImage() {
        withAnimation {
            appState.backgroundImage = nil
        }
    }

    private var customGradientStartBinding: Binding<Color> {
        Binding(
            get: { appState.customGradientStartColor },
            set: { newValue in
                appState.customGradientStartColor = newValue
                appState.useCustomGradient = true
            }
        )
    }

    private var customGradientEndBinding: Binding<Color> {
        Binding(
            get: { appState.customGradientEndColor },
            set: { newValue in
                appState.customGradientEndColor = newValue
                appState.useCustomGradient = true
                appState.useSecondCustomGradientColor = true
            }
        )
    }

    private var secondColorBinding: Binding<Bool> {
        Binding(
            get: { appState.useSecondCustomGradientColor },
            set: { newValue in
                appState.useSecondCustomGradientColor = newValue
                appState.useCustomGradient = true
            }
        )
    }

    @ViewBuilder
    private func gradientCard(title: String, colors: [Color], isSelected: Bool) -> some View {
        let previewColors = colors.isEmpty ? [Color.white] : colors
        VStack(alignment: .leading, spacing: 6) {
            if previewColors.count == 1 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(previewColors[0])
                    .frame(height: 44)
            } else {
                LinearGradient(
                    colors: previewColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Sliders Section

struct SlidersSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Blur slider
            SliderRow(title: "Blur", value: $appState.blurAmount, range: 0...100, unit: "%")

            // Padding slider
            SliderRow(title: "Padding", value: $appState.padding, range: 0...200, unit: "px")

            // Corner radius slider
            SliderRow(title: "Corner Radius", value: $appState.cornerRadius, range: 0...40, unit: "px")
        }
    }
}

// MARK: - Aspect Ratio Section

struct AspectRatioSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Canvas Ratio")
                    .font(.headline)

                Spacer()

                Picker("Canvas Ratio", selection: $appState.exportAspectRatio) {
                    ForEach(ExportAspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            if appState.exportAspectRatio == .custom {
                HStack(spacing: 12) {
                    Stepper(value: $appState.customAspectRatioWidth, in: 1...32, step: 1) {
                        Text("W \(Int(appState.customAspectRatioWidth))")
                            .font(.caption)
                    }

                    Stepper(value: $appState.customAspectRatioHeight, in: 1...32, step: 1) {
                        Text("H \(Int(appState.customAspectRatioHeight))")
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(value))\(unit)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Slider(value: $value, in: range, step: 1)
        }
    }
}

// MARK: - Export Section

struct ExportSection: View {
    @EnvironmentObject var appState: AppState
    @Binding var exportFormat: ImageFormat
    @State private var isExporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)

            HStack(spacing: 8) {
                Picker("Format", selection: $exportFormat) {
                    Text("PNG").tag(ImageFormat.png)
                    Text("JPG").tag(ImageFormat.jpeg)
                    Text("WebP").tag(ImageFormat.webp)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 84)

                Toggle(isOn: $appState.autoCopyToClipboard) {
                    Image(systemName: appState.autoCopyToClipboard ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .help("Auto-copy to clipboard")

                Spacer(minLength: 0)

                Button(action: export) {
                    HStack(spacing: 6) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Text("Export")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!appState.hasScreenshot || isExporting)
            }
        }
    }

    private func export() {
        isExporting = true
        appState.exportCurrent(format: exportFormat, copyToClipboard: appState.autoCopyToClipboard)
        // Reset local state after export completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
        }
    }
}

// MARK: - Supporting Types

enum ImageFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPG"
    case webp = "WebP"
}

#Preview {
    ControlPanelView()
        .environmentObject(AppState())
}
