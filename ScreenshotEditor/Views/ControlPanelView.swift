//
//  ControlPanelView.swift
//  ScreenshotEditor
//
//  Right panel with background and export controls
//

import SwiftUI

struct ControlPanelView: View {
    enum LayoutStyle {
        case sidebar
        case inline
    }

    @EnvironmentObject var appState: AppState
    @State private var exportFormat: ImageFormat = .png
    var layoutStyle: LayoutStyle = .sidebar

    var body: some View {
        Group {
            if layoutStyle == .inline {
                InlineCompactControlPanel(exportFormat: $exportFormat)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: stackSpacing) {
                        BackgroundSection(layoutStyle: layoutStyle)

                        Divider()

                        SlidersSection(layoutStyle: layoutStyle)

                        Divider()

                        AspectRatioSection(layoutStyle: layoutStyle)

                        Divider()

                        ExportSection(exportFormat: $exportFormat, layoutStyle: layoutStyle)
                    }
                    .padding(contentPadding)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var stackSpacing: CGFloat {
        layoutStyle == .inline ? EditorSpacing.small : EditorSpacing.medium
    }

    private var contentPadding: CGFloat {
        layoutStyle == .inline ? EditorSpacing.large : EditorSpacing.medium
    }
}

private struct InlineCompactControlPanel: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var exportFormat: ImageFormat
    @State private var isExporting = false

    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var swatchSize: CGFloat { isCompact ? 24 : 26 }
    private var swatchSpacing: CGFloat { isCompact ? EditorSpacing.xxSmall : 5 }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 7 : EditorSpacing.small) {
            VStack(alignment: .leading, spacing: EditorSpacing.xSmall) {
                Text("Background")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: swatchSpacing) {
                    ForEach(GradientPreset.presets) { preset in
                        compactSwatch(isSelected: isPresetSelected(preset)) {
                            LinearGradient(
                                colors: preset.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } action: {
                            selectPreset(preset)
                        }
                    }

                    compactSwatch(isSelected: appState.backgroundType == .none) {
                        CheckerboardView()
                    } action: {
                        selectNoneBackground()
                    }

                    compactSwatch(isSelected: appState.backgroundType == .image && appState.backgroundImage != nil) {
                        if let image = appState.backgroundImage {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray.opacity(0.18)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(EditorTypography.sectionLabel)
                                        .foregroundColor(.secondary)
                                )
                        }
                    } action: {
                        appState.requestBackgroundImageImport()
                    }
                }
            }

            sliderSection

            bottomSection
        }
        .padding(.horizontal, isCompact ? EditorSpacing.medium : EditorSpacing.large)
        .padding(.vertical, isCompact ? 7 : EditorSpacing.small)
    }

    @ViewBuilder
    private var sliderSection: some View {
        VStack(spacing: 5) {
            CompactInlineSliderRow(title: "Padding", value: $appState.padding, range: 0...200, unit: "px")
            CompactInlineSliderRow(title: "Rounded", value: $appState.cornerRadius, range: 0...40, unit: "px")
            CompactInlineSliderRow(title: "Blur", value: $appState.blurAmount, range: 0...100, unit: "%")
        }
    }

    @ViewBuilder
    private var bottomSection: some View {
        if isCompact {
            VStack(spacing: EditorSpacing.xSmall) {
                HStack(spacing: EditorSpacing.xSmall) {
                    Text("Ratio")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 34, alignment: .leading)

                    CompactMenuControl(title: appState.exportAspectRatio.rawValue, width: 72) {
                        ForEach(ExportAspectRatio.allCases, id: \.self) { ratio in
                            Button(ratio.rawValue) {
                                appState.exportAspectRatio = ratio
                            }
                        }
                    }

                    if appState.exportAspectRatio == .custom {
                        HStack(spacing: EditorSpacing.xxSmall) {
                            CompactStepper(value: $appState.customAspectRatioWidth, title: "W")
                            CompactStepper(value: $appState.customAspectRatioHeight, title: "H")
                        }
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: EditorSpacing.xSmall) {
                    CompactMenuControl(title: exportFormat.rawValue, width: 52) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Button(format.rawValue) {
                                exportFormat = format
                            }
                        }
                    }

                    clipboardButton

                    exportButton

                    Spacer(minLength: 0)
                }
            }
        } else {
            HStack(spacing: EditorSpacing.small) {
                HStack(spacing: EditorSpacing.xSmall) {
                    Text("Ratio")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    CompactMenuControl(title: appState.exportAspectRatio.rawValue, width: 74) {
                        ForEach(ExportAspectRatio.allCases, id: \.self) { ratio in
                            Button(ratio.rawValue) {
                                appState.exportAspectRatio = ratio
                            }
                        }
                    }
                }

                if appState.exportAspectRatio == .custom {
                    HStack(spacing: EditorSpacing.xxSmall) {
                        CompactStepper(value: $appState.customAspectRatioWidth, title: "W")
                        CompactStepper(value: $appState.customAspectRatioHeight, title: "H")
                    }
                } else {
                    Spacer(minLength: 0)
                }

                HStack(spacing: EditorSpacing.xSmall) {
                    CompactMenuControl(title: exportFormat.rawValue, width: 54) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Button(format.rawValue) {
                                exportFormat = format
                            }
                        }
                    }

                    clipboardButton
                    exportButton
                }
            }
        }
    }

    @ViewBuilder
    private func compactSwatch<Content: View>(isSelected: Bool, @ViewBuilder content: () -> Content, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            content()
                .frame(width: swatchSize, height: swatchSize)
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
    }

    private var clipboardButton: some View {
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
    }

    private var exportButton: some View {
        Button(action: export) {
            HStack(spacing: 3) {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.55)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(EditorTypography.compactLabel)
                }

                Text("Export")
                    .font(EditorTypography.microLabel)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, EditorSpacing.xxSmall)
            .background(
                RoundedRectangle(cornerRadius: EditorCornerRadius.compact, style: .continuous)
                    .fill(Color.accentColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(!appState.hasScreenshot || isExporting)
        .opacity((!appState.hasScreenshot || isExporting) ? 0.55 : 1)
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

    private func isPresetSelected(_ preset: GradientPreset) -> Bool {
        appState.backgroundType == .color && appState.selectedGradient.id == preset.id
    }

    private func export() {
        isExporting = true
        appState.exportCurrent(format: exportFormat, copyToClipboard: appState.autoCopyToClipboard)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isExporting = false
        }
    }
}

struct CompactInlineSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        HStack(spacing: EditorSpacing.xSmall) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .leading)

            CompactInlineSlider(value: $value, range: range)
                .frame(maxWidth: .infinity)

            Text("\(Int(value))\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .frame(height: 18)
    }
}

struct CompactInlineSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let knobSize: CGFloat = 10
            let progress = normalizedValue
            let availableWidth = max(proxy.size.width - knobSize, 1)
            let knobX = progress * availableWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.accentColor.opacity(0.9))
                    .frame(width: knobX + knobSize / 2, height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(EditorOpacity.accentFill), radius: 1, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.9), lineWidth: 1)
                    )
                    .offset(x: knobX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let location = min(max(gesture.location.x, 0), proxy.size.width)
                        let percent = location / max(proxy.size.width, 1)
                        let rawValue = range.lowerBound + percent * (range.upperBound - range.lowerBound)
                        value = rawValue.rounded()
                    }
            )
        }
        .frame(height: 14)
    }

    private var normalizedValue: CGFloat {
        let total = range.upperBound - range.lowerBound
        guard total > 0 else { return 0 }
        return CGFloat((value - range.lowerBound) / total)
    }
}

struct CompactMenuControl<MenuContent: View>: View {
    let title: String
    let width: CGFloat
    @ViewBuilder let content: () -> MenuContent

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 3) {
                Text(title)
                    .font(EditorTypography.microLabel)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundColor(.primary)
            .frame(width: width, height: 22)
            .background(
                RoundedRectangle(cornerRadius: EditorCornerRadius.compact, style: .continuous)
                    .fill(Color.secondary.opacity(EditorOpacity.subtleFill))
            )
        }
        .menuStyle(.borderlessButton)
    }
}

struct CompactStepper: View {
    @Binding var value: Double
    let title: String

    var body: some View {
        HStack(spacing: 3) {
            compactButton(systemImage: "minus") {
                value = max(1, value - 1)
            }

            Text("\(title) \(Int(value))")
                .font(EditorTypography.microLabel)
                .foregroundColor(.secondary)
                .frame(minWidth: 32)

            compactButton(systemImage: "plus") {
                value = min(32, value + 1)
            }
        }
    }

    private func compactButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 16, height: 16)
                .background(
                    RoundedRectangle(cornerRadius: EditorCornerRadius.tiny, style: .continuous)
                        .fill(Color.secondary.opacity(EditorOpacity.subtleFill))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background Section

struct BackgroundSection: View {
    @EnvironmentObject var appState: AppState
    let layoutStyle: ControlPanelView.LayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: EditorSpacing.small) {
            Text("Background")
                .font(sectionHeaderFont)

            LazyVGrid(columns: swatchColumns, spacing: EditorSpacing.small) {
                ForEach(GradientPreset.presets) { preset in
                    Button(action: { selectPreset(preset) }) {
                        SwatchCard(
                            title: preset.name,
                            isSelected: isPresetSelected(preset),
                            size: swatchSize
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
                    SwatchCard(title: "None", isSelected: appState.backgroundType == .none, size: swatchSize) {
                        CheckerboardView()
                    }
                }
                .buttonStyle(.plain)

                Button(action: selectBackgroundImage) {
                    SwatchCard(title: "More...", isSelected: appState.backgroundType == .image && appState.backgroundImage != nil, size: swatchSize) {
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
        Array(
            repeating: GridItem(
                .flexible(minimum: swatchSize - EditorSpacing.xxSmall, maximum: swatchSize + EditorSpacing.small),
                spacing: EditorSpacing.small
            ),
            count: 5
        )
    }

    private var swatchSize: CGFloat {
        layoutStyle == .inline ? 44 : 52
    }

    private var sectionHeaderFont: Font {
        layoutStyle == .inline ? .subheadline.weight(.semibold) : .headline
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
    let size: CGFloat
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        VStack(spacing: EditorSpacing.xxSmall) {
            preview()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: EditorCornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: EditorCornerRadius.medium)
                        .stroke(
                            isSelected ? Color.accentColor : Color.gray.opacity(EditorOpacity.swatchStrongStroke),
                            lineWidth: isSelected ? 2.0 : 1.0
                        )
                )

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: size)
        }
    }
}

struct CheckerboardView: View {
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
                    context.fill(Path(rect), with: .color(Color.gray.opacity(EditorOpacity.swatchStrongStroke)))
                }
            }
        }
        .background(Color.white.opacity(0.82))
    }
}

// MARK: - Sliders Section

struct SlidersSection: View {
    @EnvironmentObject var appState: AppState
    let layoutStyle: ControlPanelView.LayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adjust")
                .font(layoutStyle == .inline ? .subheadline.weight(.semibold) : .headline)
            
            // Padding slider
            SliderRow(title: "Padding", value: $appState.padding, range: 0...200, unit: "px", layoutStyle: layoutStyle)

            SliderRow(title: "Rounded", value: $appState.cornerRadius, range: 0...40, unit: "px", layoutStyle: layoutStyle)
            SliderRow(title: "BG Blur", value: $appState.blurAmount, range: 0...100, unit: "%", layoutStyle: layoutStyle)
        }
    }
}

// MARK: - Aspect Ratio Section

struct AspectRatioSection: View {
    @EnvironmentObject var appState: AppState
    let layoutStyle: ControlPanelView.LayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Canvas Ratio")
                    .font(layoutStyle == .inline ? .subheadline.weight(.semibold) : .headline)

                Spacer()

                Picker("Canvas Ratio", selection: $appState.exportAspectRatio) {
                    ForEach(ExportAspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: layoutStyle == .inline ? 110 : 120)
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
    let layoutStyle: ControlPanelView.LayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(layoutStyle == .inline ? .caption2 : .caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(value))\(unit)")
                    .font(layoutStyle == .inline ? .caption2 : .caption)
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
    let layoutStyle: ControlPanelView.LayoutStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(layoutStyle == .inline ? .subheadline.weight(.semibold) : .headline)

            HStack(spacing: 8) {
                Picker("Format", selection: $exportFormat) {
                    Text("PNG").tag(ImageFormat.png)
                    Text("JPG").tag(ImageFormat.jpeg)
                    Text("WebP").tag(ImageFormat.webp)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: layoutStyle == .inline ? 76 : 84)

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
                                .font(.system(size: layoutStyle == .inline ? 11 : 12, weight: .semibold))
                        }
                        Text("Export")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, layoutStyle == .inline ? 8 : 10)
                    .padding(.vertical, layoutStyle == .inline ? 5 : 6)
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
