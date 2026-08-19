import Foundation

// MARK: - YtDlp Service

/// Builds yt-dlp command arguments and executes downloads as child processes,
/// streaming stdout/stderr through OutputParser for real-time progress.
class YtDlpService {

    enum ServiceError: LocalizedError {
        case binaryNotFound
        case processError(String)

        var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                "yt-dlp not found. Install via Homebrew: brew install yt-dlp"
            case .processError(let msg):
                msg
            }
        }
    }

    // MARK: - Argument Builder

    /// Mirrors the exact yt-dlp flags from the original shell/batch scripts.
    func buildArguments(for task: DownloadTask, downloadDir: URL) -> [String] {
        var args = [String]()
        let outputTemplate = downloadDir.appendingPathComponent("%(title)s.%(ext)s").path

        switch task.mode {
        case .bestVideo:
            args += [
                "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best",
                "--merge-output-format", "mp4",
                "-o", outputTemplate,
            ]

        case .audioOnly:
            args += [
                "-x",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "-o", outputTemplate,
            ]

        case .selectQuality:
            let res = task.options.quality.rawValue
            args += [
                "-f",
                "bestvideo[height<=\(res)][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=\(res)]+bestaudio/best[height<=\(res)]",
                "--merge-output-format", "mp4",
                "-o", outputTemplate,
            ]

        case .playlist:
            let playlistTemplate = downloadDir
                .appendingPathComponent("Playlist/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s")
                .path
            args += [
                "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best",
                "--merge-output-format", "mp4",
                "--yes-playlist",
                "-o", playlistTemplate,
            ]
            if case .range(let start, let end) = task.options.playlistRange {
                args += [
                    "--playlist-start", "\(start)",
                    "--playlist-end", "\(end)",
                ]
            }

        case .videoWithSubtitles:
            let lang = task.options.effectiveSubtitleCode
            args += [
                "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best",
                "--merge-output-format", "mp4",
                "--write-subs", "--write-auto-subs",
                "--sub-langs", lang,
                "--embed-subs",
                "-o", outputTemplate,
            ]

        case .subtitleOnly:
            let lang = task.options.effectiveSubtitleCode
            args += [
                "--write-subs", "--write-auto-subs",
                "--sub-langs", lang,
                "--skip-download",
                "--convert-subs", "srt",
                "-o", outputTemplate,
            ]

        case .customFormat:
            args += [
                "-f", task.options.customFormatId,
                "-o", outputTemplate,
            ]
        }

        // Force one progress line per update (instead of \r overwrites)
        args += ["--newline"]

        // The URL is always the last argument
        args.append(task.url)

        return args
    }

    // MARK: - Execute

    /// Runs yt-dlp as a child process, streaming events via `onEvent`.
    /// The closure is called from a background thread; callers should
    /// dispatch to `@MainActor` themselves.
    func execute(
        task: DownloadTask,
        downloadDir: URL,
        onEvent: @escaping @Sendable (OutputEvent) -> Void
    ) async throws {
        guard let ytDlpURL = await BinaryManager.shared.ytDlpURL else {
            throw ServiceError.binaryNotFound
        }

        let arguments = buildArguments(for: task, downloadDir: downloadDir)
        let environment = await BinaryManager.shared.buildEnvironment()

        // Ensure download directory exists
        try FileManager.default.createDirectory(
            at: downloadDir,
            withIntermediateDirectories: true
        )

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = ytDlpURL
        process.arguments = arguments
        process.environment = environment
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Store process reference so it can be cancelled
        await MainActor.run { task.process = process }

        // Stream stdout
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let text = String(data: data, encoding: .utf8)
            else { return }

            for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                if let event = OutputParser.parse(line: line) {
                    onEvent(event)
                }
            }
        }

        // Stream stderr (yt-dlp writes progress info here too)
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let text = String(data: data, encoding: .utf8)
            else { return }

            for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                if let event = OutputParser.parse(line: line) {
                    onEvent(event)
                }
            }
        }

        try process.run()

        // Yield the current actor while the process runs
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        // Clean up handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Check for errors (ignore if we were cancelled)
        let wasCancelled: Bool = await MainActor.run {
            if case .cancelled = task.status { return true }
            return false
        }

        if process.terminationStatus != 0 && !wasCancelled {
            throw ServiceError.processError(
                "yt-dlp exited with code \(process.terminationStatus)"
            )
        }
    }

    // MARK: - Format Listing

    /// Runs `yt-dlp -F <url>` and returns the raw output for display.
    func fetchFormats(url: String) async throws -> String {
        guard let ytDlpURL = await BinaryManager.shared.ytDlpURL else {
            throw ServiceError.binaryNotFound
        }

        let environment = await BinaryManager.shared.buildEnvironment()

        let process = Process()
        let pipe = Pipe()

        process.executableURL = ytDlpURL
        process.arguments = ["-F", url]
        process.environment = environment
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? "No format information available."
    }
}
