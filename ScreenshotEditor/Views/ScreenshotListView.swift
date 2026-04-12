//
//  ScreenshotListView.swift
//  ScreenshotEditor
//
//  Left sidebar showing screenshot thumbnails
//

#if os(macOS)
import SwiftUI

struct ScreenshotListView: View {
    @EnvironmentObject var appState: AppState
    @State private var isMultiSelectMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with multi-select toggle
            HStack {
                Text("Recent Imports")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !appState.screenshots.isEmpty {
                    Button(action: { isMultiSelectMode.toggle() }) {
                        Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isMultiSelectMode ? .accentColor : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Toggle multi-select for batch export")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Screenshot list
            List(selection: $appState.selectedScreenshotId) {
                ForEach(appState.screenshots) { screenshot in
                    ScreenshotThumbnailView(screenshot: screenshot)
                        .tag(screenshot.id)
                        .contextMenu {
                            Button("Delete") {
                                appState.deleteScreenshot(screenshot)
                            }
                            Button("Show in Finder") {
                                if let url = screenshot.sourceURL {
                                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                                }
                            }
                            if !isMultiSelectMode {
                                Divider()
                                Button("Select for Batch Export") {
                                    isMultiSelectMode = true
                                }
                            }
                        }
                }
                .onMove { source, destination in
                    appState.screenshots.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.sidebar)

            // Empty state
            if appState.screenshots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)

                    Text("No Screenshots")
                        .font(.headline)

                    Text("Drag and drop a screenshot here\nor click Import (⌘O)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Import...") {
                        appState.importScreenshot()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .onDrop(of: [.image], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        // TODO: Handle dropped images
    }
}

// MARK: - Screenshot Thumbnail View

struct ScreenshotThumbnailView: View {
    let screenshot: Screenshot

    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail
            Group {
                if let thumbnail = screenshot.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 60, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Name
            Text(screenshot.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScreenshotListView()
        .environmentObject(AppState())
}
#endif
