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

            // Gradient presets
            if appState.backgroundType == .gradient {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gradient Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(GradientPreset.presets) { preset in
                            Button(action: {
                                withAnimation {
                                    appState.selectedGradient = preset
                                }
                            }) {
                                LinearGradient(
                                    colors: preset.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 50)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(appState.selectedGradient.id == preset.id ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Color picker (for solid color mode)
            if appState.backgroundType == .solid {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Solid Color")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28)), GridItem(.fixed(28))], spacing: 6) {
                        ForEach([Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple, Color.gray, Color.black], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(appState.selectedColor == color ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    withAnimation {
                                        appState.selectedColor = color
                                    }
                                }
                        }
                    }
                }
            }
        }
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

            // Format picker
            Picker("Format", selection: $exportFormat) {
                Text("PNG").tag(ImageFormat.png)
                Text("JPG").tag(ImageFormat.jpeg)
                Text("WebP").tag(ImageFormat.webp)
            }
            .pickerStyle(.segmented)

            // Export button
            Button(action: export) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("Export Image...")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!appState.hasScreenshot || isExporting)

            // Options
            Toggle("Auto-copy to clipboard", isOn: $appState.autoCopyToClipboard)
                .font(.caption)
                .foregroundColor(.secondary)
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
