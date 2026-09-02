import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var downloadManager: DownloadManager
    @State private var ytDlpVersion: String = "Checking…"
    @State private var isUpdating = false
    @State private var updateResult: String?
    @State private var ytDlpFound = true

    var body: some View {
        Form {
            downloadsSection
            ytDlpSection
            aboutSection
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task { await checkVersion() }
    }

    // MARK: - Downloads Section

    private var downloadsSection: some View {
        Section("Downloads") {
            HStack {
                Label("Download Folder", systemImage: "folder.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Text(downloadManager.downloadDirectory.lastPathComponent)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Button("Change…") { selectDownloadDirectory() }
            }

            Picker(
                selection: $downloadManager.maxConcurrentDownloads
            ) {
                ForEach(1...5, id: \.self) { num in
                    Text("\(num)").tag(num)
                }
            } label: {
                Label("Max Concurrent Downloads", systemImage: "arrow.down.to.line.compact")
            }
            .onChange(of: downloadManager.maxConcurrentDownloads) { _, _ in
                downloadManager.saveSettings()
            }
        }
    }

    // MARK: - yt-dlp Section

    private var ytDlpSection: some View {
        Section("yt-dlp") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                if ytDlpFound {
                    Text(ytDlpVersion)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                } else {
                    Label("Not installed", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            HStack {
                Label("Update", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Button(action: updateYtDlp) {
                    if isUpdating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Updating…")
                        }
                    } else {
                        Text("Check for Updates")
                    }
                }
                .disabled(isUpdating || !ytDlpFound)
            }

            if let result = updateResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !ytDlpFound {
                VStack(alignment: .leading, spacing: 4) {
                    Text("yt-dlp is required for downloads.")
                        .font(.caption)
                    Text("Install via Homebrew: brew install yt-dlp")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("EasyDLP", systemImage: "play.rectangle.fill")
                Spacer()
                Text("v2.0 (macOS)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Source", systemImage: "chevron.left.forwardslash.chevron.right")
                Spacer()
                Link("GitHub", destination: URL(string: "https://github.com/bezelye404/EasyDLP")!)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    // MARK: - Actions

    private func selectDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.message = "Choose a folder for downloads"

        if panel.runModal() == .OK, let url = panel.url {
            downloadManager.downloadDirectory = url
            downloadManager.saveSettings()
        }
    }

    private func checkVersion() async {
        do {
            let version = try await BinaryManager.shared.ytDlpVersion()
            ytDlpVersion = version
            ytDlpFound = true
        } catch {
            ytDlpVersion = "–"
            ytDlpFound = false
        }
    }

    private func updateYtDlp() {
        isUpdating = true
        updateResult = nil
        Task {
            do {
                let result = try await BinaryManager.shared.updateYtDlp()
                updateResult = result
                isUpdating = false
                await checkVersion()
            } catch {
                updateResult = "Error: \(error.localizedDescription)"
                isUpdating = false
            }
        }
    }
}
