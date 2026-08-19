import Foundation

// MARK: - Binary Manager

/// Locates and manages the yt-dlp and ffmpeg binaries.
/// Checks the app bundle first, then common system paths.
actor BinaryManager {
    static let shared = BinaryManager()

    enum BinaryError: LocalizedError {
        case notFound(String)
        case permissionDenied(String)
        case updateFailed(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let name):
                "Could not find \(name). Please install it via Homebrew: brew install \(name)"
            case .permissionDenied(let name):
                "Permission denied when trying to execute \(name)."
            case .updateFailed(let reason):
                "Failed to update: \(reason)"
            }
        }
    }

    // MARK: - Binary Location

    /// Searches for a binary by name: bundle → common paths → `which`
    func locateBinary(named name: String) -> URL? {
        // 1. Bundled binaries inside the .app
        if let bundledURL = Bundle.main.resourceURL?.appendingPathComponent("bin/\(name)") {
            if FileManager.default.isExecutableFile(atPath: bundledURL.path) {
                return bundledURL
            }
            // Try fixing permissions
            if FileManager.default.fileExists(atPath: bundledURL.path) {
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: bundledURL.path
                )
                if FileManager.default.isExecutableFile(atPath: bundledURL.path) {
                    return bundledURL
                }
            }
        }

        // 2. Common system paths
        let searchPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
        ]
        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        // 3. Fallback: ask the shell via `which`
        return whichBinary(name)
    }

    var ytDlpURL: URL? {
        locateBinary(named: "yt-dlp")
    }

    var ffmpegURL: URL? {
        locateBinary(named: "ffmpeg")
    }

    // MARK: - Version / Update

    func ytDlpVersion() async throws -> String {
        guard let url = ytDlpURL else {
            throw BinaryError.notFound("yt-dlp")
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = url
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
    }

    func updateYtDlp() async throws -> String {
        guard let url = ytDlpURL else {
            throw BinaryError.notFound("yt-dlp")
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = url
        process.arguments = ["-U"]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw BinaryError.updateFailed(output)
        }
        return output
    }

    // MARK: - Environment

    /// Builds a process environment with all binary locations on PATH.
    func buildEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        var paths = [String]()

        if let bundledBin = Bundle.main.resourceURL?.appendingPathComponent("bin") {
            paths.append(bundledBin.path)
        }

        paths.append(contentsOf: [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
        ])

        if let existingPath = env["PATH"] {
            paths.append(existingPath)
        }

        env["PATH"] = paths.joined(separator: ":")
        return env
    }

    // MARK: - Helpers

    private func whichBinary(_ name: String) -> URL? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty
            {
                return URL(fileURLWithPath: path)
            }
        } catch {
            // Silently fail — binary simply not found
        }
        return nil
    }
}
