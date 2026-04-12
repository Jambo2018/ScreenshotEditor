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
            VStack(alignment: .leading, spacing: 10) {
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
            .padding(10)
        }
    }
}

// MARK: - Background Section

struct BackgroundSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background")
                .font(.headline)

            LazyVGrid(columns: swatchColumns, spacing: 8) {
                ForEach(GradientPreset.presets) { preset in
                    Button(action: { selectPreset(preset) }) {
                        SwatchCard(
                            title: preset.name,
                            isSelected: isPresetSelected(preset)
                        ) {
                            LinearGradient(
                                colors: preset.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button(action: selectNoneBackground) {
                    SwatchCard(title: "None", isSelected: appState.backgroundType == .none) {
                        CheckerboardView()
                    }
                }
                .buttonStyle(.plain)

                Button(action: selectBackgroundImage) {
                    SwatchCard(title: "More...", isSelected: appState.backgroundType == .image && appState.backgroundImage != nil) {
                        if let image = appState.backgroundImage {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.76, blue: 0.60), Color(red: 0.67, green: 0.82, blue: 0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Image(systemName: "ellipsis")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var swatchColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 44, maximum: 64), spacing: 8), count: 5)
    }

    private func selectBackgroundImage() {
        appState.requestBackgroundImageImport()
    }

    private func selectPreset(_ preset: GradientPreset) {
        withAnimation {
            appState.backgroundType = .color
            appState.selectedGradient = preset
            appState.backgroundImage = nil
            appState.useCustomGradient = false
        }
    }

    private func selectNoneBackground() {
        withAnimation {
            appState.backgroundType = .none
            appState.backgroundImage = nil
            appState.useCustomGradient = false
        }
    }

    private func isPresetSelected(_ preset: GradientPreset) -> Bool {
        appState.backgroundType == .color && appState.selectedGradient.id == preset.id
    }
}

private struct SwatchCard<Preview: View>: View {
    let title: String
    let isSelected: Bool
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        VStack(spacing: 4) {
            preview()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.28), lineWidth: isSelected ? 2.0 : 1.0)
                )

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 52)
        }
    }
}

private struct CheckerboardView: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 8
            let rows = Int(ceil(size.height / tileSize))
            let cols = Int(ceil(size.width / tileSize))

            for row in 0..<rows {
                for col in 0..<cols where (row + col).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(Path(rect), with: .color(Color.gray.opacity(0.28)))
                }
            }
        }
        .background(Color.white.opacity(0.82))
    }
}

// MARK: - Sliders Section

struct SlidersSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adjust")
                .font(.headline)
            
            // Padding slider
            SliderRow(title: "Padding", value: $appState.padding, range: 0...200, unit: "px")

            SliderRow(title: "Rounded", value: $appState.cornerRadius, range: 0...40, unit: "px")
            SliderRow(title: "BG Blur", value: $appState.blurAmount, range: 0...100, unit: "%")
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
        VStack(alignment: .leading, spacing: 4) {
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
