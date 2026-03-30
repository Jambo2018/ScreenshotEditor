//
//  HistoryView.swift
//  ScreenshotEditor
//
//  History browsing view with grouped thumbnails
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var groupedScreenshots: [String: [Screenshot]] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            HStack {
                Text("历史记录")
                    .font(.headline)

                Spacer()

                Button(action: deleteAll) {
                    Label("删除全部", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .disabled(appState.screenshots.isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("搜索文件名...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, _ in
                        filterScreenshots()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            // Grouped screenshots
            if groupedScreenshots.isEmpty {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无历史记录")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedScreenshots.keys.sorted(), id: \.self) { groupName in
                            if let screenshots = groupedScreenshots[groupName], !screenshots.isEmpty {
                                SectionView(groupName: groupName, screenshots: screenshots)
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            filterScreenshots()
        }
    }

    private func filterScreenshots() {
        let allScreenshots = appState.screenshots

        let filtered: [Screenshot]
        if searchText.isEmpty {
            filtered = allScreenshots
        } else {
            filtered = allScreenshots.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Group by date
        groupedScreenshots = groupScreenshotsByDate(filtered)
    }

    private func groupScreenshotsByDate(_ screenshots: [Screenshot]) -> [String: [Screenshot]] {
        let calendar = Calendar.current
        var groups: [String: [Screenshot]] = [:]

        let today = Date()

        for screenshot in screenshots {
            let date = screenshot.createdAt
            var groupName: String

            if calendar.isDateInToday(date) {
                groupName = "今天"
            } else if calendar.isDateInYesterday(date) {
                groupName = "昨天"
            } else if calendar.isDate(date, equalTo: today, toGranularity: .weekOfYear) {
                groupName = "本周"
            } else if calendar.isDate(date, equalTo: today, toGranularity: .month) {
                groupName = "本月"
            } else {
                // Group by month/year for older screenshots
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy 年 M 月"
                formatter.locale = Locale(identifier: "zh_CN")
                groupName = formatter.string(from: date)
            }

            if groups[groupName] == nil {
                groups[groupName] = []
            }
            groups[groupName]?.append(screenshot)
        }

        return groups
    }

    private func deleteAll() {
        appState.screenshots.removeAll()
        appState.selectedScreenshotId = nil
        filterScreenshots()
    }
}

// MARK: - Section View

struct SectionView: View {
    let groupName: String
    let screenshots: [Screenshot]
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(groupName)
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120, maximum: 160))], spacing: 12) {
                ForEach(screenshots) { screenshot in
                    HistoryThumbnailView(screenshot: screenshot)
                        .onTapGesture {
                            appState.selectedScreenshotId = screenshot.id
                        }
                        .contextMenu {
                            Button(action: {
                                appState.deleteScreenshot(screenshot)
                            }) {
                                Text("删除")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - History Thumbnail View

struct HistoryThumbnailView: View {
    let screenshot: Screenshot
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail image
            if let cgImage = screenshot.image?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 80)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(appState.selectedScreenshotId == screenshot.id ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 80)
                    .cornerRadius(6)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }

            // Name label
            Text(screenshot.name)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
