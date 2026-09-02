import Foundation
import os

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
                AppLogger.info(.binary, "Found \(name) in app bundle: \(bundledURL.path)")
                return bundledURL
            }
            // Try fixing permissions
            if FileManager.default.fileExists(atPath: bundledURL.path) {
                AppLogger.debug(.binary, "\(name) exists in bundle but not executable, attempting chmod")
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: bundledURL.path
                )
                if FileManager.default.isExecutableFile(atPath: bundledURL.path) {
                    AppLogger.info(.binary, "Fixed permissions for bundled \(name)")
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
                AppLogger.info(.binary, "Found \(name) at system path: \(path)")
                return URL(fileURLWithPath: path)
            }
        }
        AppLogger.debug(.binary, "\(name) not found in common system paths, trying 'which'")

        // 3. Fallback: ask the shell via `which`
        let result = whichBinary(name)
        if let result {
            AppLogger.info(.binary, "Found \(name) via 'which': \(result.path)")
        } else {
            AppLogger.warning(.binary, "\(name) not found anywhere")
        }
        return result
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
            AppLogger.warning(.binary, "Cannot check yt-dlp version — binary not found")
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
        let version = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        AppLogger.info(.binary, "yt-dlp version: \(version)")
        return version
    }

    func updateYtDlp() async throws -> String {
        guard let url = ytDlpURL else {
            AppLogger.warning(.binary, "Cannot update yt-dlp — binary not found")
            throw BinaryError.notFound("yt-dlp")
        }

        AppLogger.info(.binary, "Starting yt-dlp update")

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
            AppLogger.error(.binary, "yt-dlp update failed: \(output)")
            throw BinaryError.updateFailed(output)
        }
        AppLogger.info(.binary, "yt-dlp update completed: \(output.prefix(200))")
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
        AppLogger.debug(.binary, "Built environment PATH: \(paths.prefix(4).joined(separator: ":"))...")
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
