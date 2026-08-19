import SwiftUI

// MARK: - Download List View

struct DownloadListView: View {
    @Bindable var downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if downloadManager.downloads.isEmpty {
                emptyState
            } else {
                downloadsList
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Downloads")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !downloadManager.completedDownloads.isEmpty {
                Button("Clear Completed") {
                    withAnimation(.easeInOut) {
                        downloadManager.clearCompleted()
                    }
                }
                .buttonStyle(.bordered)
            }

            Button {
                NSWorkspace.shared.open(downloadManager.downloadDirectory)
            } label: {
                Label("Open Folder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }

    private var summaryText: String {
        let active = downloadManager.activeDownloads.count
        let completed = downloadManager.completedDownloads.count
        if active == 0 && completed == 0 {
            return "No downloads"
        }
        return "\(active) active, \(completed) completed"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No Downloads Yet")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("Start a download from the New Download tab")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Downloads List

    private var downloadsList: some View {
        List {
            let active = downloadManager.activeDownloads
            if !active.isEmpty {
                Section("Active") {
                    ForEach(active) { task in
                        downloadRow(for: task)
                    }
                }
            }

            let inactive = downloadManager.downloads.filter { !$0.status.isActive }
            if !inactive.isEmpty {
                Section("History") {
                    ForEach(inactive) { task in
                        downloadRow(for: task)
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private func downloadRow(for task: DownloadTask) -> some View {
        DownloadRowView(
            task: task,
            onCancel: { downloadManager.cancelDownload(task) },
            onRemove: { withAnimation { downloadManager.removeDownload(task) } },
            onRetry: { downloadManager.retryDownload(task) },
            onReveal: { downloadManager.revealInFinder(task) }
        )
    }
}
