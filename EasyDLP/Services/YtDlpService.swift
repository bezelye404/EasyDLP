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
    func buildArguments(for task: DownloadTask, downloadDir: URL, ffmpegURL: URL?) -> [String] {
        var args = [String]()

        // Let yt-dlp pick the best client (currently android_vr) — full DASH formats, no 403
        args += ["--extractor-args", "youtube:player-client=default"]
        if let ffmpeg = ffmpegURL {
            args += ["--ffmpeg-location", ffmpeg.path]
        }
        
        let outputTemplate = downloadDir.appendingPathComponent("%(title)s.%(ext)s").path

        switch task.mode {
        case .bestVideo:
            args += [
                "-f", "bestvideo+bestaudio/best",
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
                "bestvideo[height<=\(res)]+bestaudio/best[height<=\(res)]",
                "--merge-output-format", "mp4",
                "-o", outputTemplate,
            ]

        case .playlist:
            let playlistTemplate = downloadDir
                .appendingPathComponent("Playlist/%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s")
                .path
            args += [
                "-f", "bestvideo+bestaudio/best",
                "--merge-output-format", "mp4",
                "-o", playlistTemplate,
                "--yes-playlist"
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
                "-f", "bestvideo+bestaudio/best",
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

        // Avoid stale cached video URLs and IPv6 CDN issues
        args += ["--no-cache-dir", "--force-ipv4"]

        // Retry on transient 403 errors during download
        args += ["--retries", "10", "--fragment-retries", "10"]

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

        let ffmpegURL = await BinaryManager.shared.ffmpegURL
        let arguments = buildArguments(for: task, downloadDir: downloadDir, ffmpegURL: ffmpegURL)

        // Debug: log the full command so we can diagnose issues
        print("▶ yt-dlp binary: \(ytDlpURL.path)")
        print("▶ ffmpeg: \(ffmpegURL?.path ?? "NOT FOUND")")
        print("▶ full command: \(ytDlpURL.path) \(arguments.joined(separator: " "))")

        // Ensure download directory exists
        try FileManager.default.createDirectory(
            at: downloadDir,
            withIntermediateDirectories: true
        )

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        // Run via login shell to inherit the full terminal environment,
        // which avoids HTTP 403 errors caused by missing env vars in GUI apps.
        let shellCommand = ([ytDlpURL.path] + arguments)
            .map { arg in
                // Shell-escape each argument
                "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'"
            }
            .joined(separator: " ")

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", shellCommand]
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
                print("yt-dlp stderr: \(line)")
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



        let process = Process()
        let pipe = Pipe()

        let shellCommand = "'\(ytDlpURL.path)' '-F' '\(url.replacingOccurrences(of: "'", with: "'\\''"))'"
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", shellCommand]
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
