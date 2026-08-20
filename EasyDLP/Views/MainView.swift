import SwiftUI

// MARK: - Sidebar Item

enum SidebarItem: String, Identifiable, CaseIterable {
    case newDownload = "New Download"
    case downloads = "Downloads"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .newDownload: "plus.circle.fill"
        case .downloads: "arrow.down.circle.fill"
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @State private var selectedItem: SidebarItem? = .newDownload
    @Bindable var downloadManager: DownloadManager

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
                .frame(minWidth: 600, minHeight: 400)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundStyle(Color.brandGold)
                    Text("EasyDLP")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedItem) {
            Section("Menu") {
                ForEach(SidebarItem.allCases) { item in
                    sidebarRow(for: item)
                        .tag(item)
                }
            }

            Section {
                Button {
                    NSWorkspace.shared.open(downloadManager.downloadDirectory)
                } label: {
                    Label("Open Downloads", systemImage: "folder")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
    }

    private func sidebarRow(for item: SidebarItem) -> some View {
        Label {
            HStack {
                Text(item.rawValue)
                Spacer()
                if item == .downloads && downloadManager.activeCount > 0 {
                    Text("\(downloadManager.activeCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brandGold, in: Capsule())
                }
            }
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(Color.brandGold)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .newDownload, nil:
            NewDownloadView(downloadManager: downloadManager)
        case .downloads:
            DownloadListView(downloadManager: downloadManager)
        }
    }
}
