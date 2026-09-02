import Foundation
import Observation
import AppKit
import os

// MARK: - Download Manager

/// Observable download queue manager. Owns the list of downloads,
/// starts/cancels tasks, and persists user preferences.
@Observable
class DownloadManager {

    var downloads: [DownloadTask] = []
    var downloadDirectory: URL
    var maxConcurrentDownloads: Int

    private let ytDlpService = YtDlpService()

    // MARK: - Computed

    var activeDownloads: [DownloadTask] {
        downloads.filter { $0.status.isActive }
    }

    var completedDownloads: [DownloadTask] {
        downloads.filter {
            if case .completed = $0.status { return true }
            return false
        }
    }

    var activeCount: Int { activeDownloads.count }

    // MARK: - Init

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: "downloadDirectory") {
            self.downloadDirectory = URL(fileURLWithPath: savedPath)
        } else {
            self.downloadDirectory = FileManager.default.urls(
                for: .downloadsDirectory,
                in: .userDomainMask
            ).first!
        }

        let saved = UserDefaults.standard.integer(forKey: "maxConcurrentDownloads")
        self.maxConcurrentDownloads = saved > 0 ? saved : 2
    }

    // MARK: - Download Lifecycle

    func startDownload(url: String, mode: DownloadMode, options: DownloadOptions) {
        let task = DownloadTask(url: url, mode: mode, options: options)
        downloads.insert(task, at: 0)
        AppLogger.info(.downloads, "Queued download — mode: \(mode.rawValue), url: \(url.prefix(80))")
        Task { await executeDownload(task) }
    }

    func cancelDownload(_ task: DownloadTask) {
        AppLogger.info(.downloads, "Cancelling download: \(task.displayTitle)")
        task.status = .cancelled
        task.process?.terminate()
    }

    func removeDownload(_ task: DownloadTask) {
        if task.status.isActive {
            cancelDownload(task)
        }
        AppLogger.info(.downloads, "Removed download: \(task.displayTitle)")
        downloads.removeAll { $0.id == task.id }
    }

    func retryDownload(_ task: DownloadTask) {
        AppLogger.info(.downloads, "Retrying download: \(task.displayTitle)")
        task.status = .queued
        task.outputLines.removeAll()
        Task { await executeDownload(task) }
    }

    func revealInFinder(_ task: DownloadTask) {
        if let outputPath = task.outputPath {
            NSWorkspace.shared.activateFileViewerSelecting([outputPath])
        } else {
            NSWorkspace.shared.open(downloadDirectory)
        }
    }

    func clearCompleted() {
        downloads.removeAll {
            if case .completed = $0.status { return true }
            return false
        }
    }

    // MARK: - Settings

    func saveSettings() {
        UserDefaults.standard.set(downloadDirectory.path, forKey: "downloadDirectory")
        UserDefaults.standard.set(maxConcurrentDownloads, forKey: "maxConcurrentDownloads")
        AppLogger.debug(.downloads, "Settings saved — dir: \(downloadDirectory.lastPathComponent), concurrent: \(maxConcurrentDownloads)")
    }

    // MARK: - Private

    private func executeDownload(_ task: DownloadTask) async {
        await MainActor.run {
            task.status = .fetching
            AppLogger.info(.downloads, "Download started — fetching info for: \(task.displayTitle)")
        }

        do {
            try await ytDlpService.execute(
                task: task,
                downloadDir: downloadDirectory
            ) { [weak self] event in
                Task { @MainActor in
                    self?.handleEvent(event, for: task)
                }
            }

            await MainActor.run {
                if case .cancelled = task.status { return }
                task.status = .completed
                AppLogger.info(.downloads, "Download completed: \(task.displayTitle)")
            }
        } catch {
            await MainActor.run {
                if case .cancelled = task.status { return }
                task.status = .failed(error: error.localizedDescription)
                AppLogger.warning(.downloads, "Download failed: \(task.displayTitle) — \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func handleEvent(_ event: OutputEvent, for task: DownloadTask) {
        switch event {
        case .progress(let progress):
            task.status = .downloading(
                progress: progress.percentage,
                speed: progress.speed,
                eta: progress.eta
            )

        case .destination(let title):
            if task.title == nil {
                task.title = title
            }

        case .merging:
            task.status = .merging

        case .converting:
            task.status = .converting

        case .error(let msg):
            task.status = .failed(error: msg)

        case .info(let line):
            task.outputLines.append(line)
        }
    }
}
