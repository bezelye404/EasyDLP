import Foundation
import os

// MARK: - Download Progress

struct DownloadProgress: Equatable {
    var percentage: Double // 0.0 to 1.0
    var totalSize: String?
    var speed: String?
    var eta: String?
}

// MARK: - Output Event

enum OutputEvent {
    case progress(DownloadProgress)
    case destination(String)
    case merging
    case converting
    case error(String)
    case info(String)
}

// MARK: - Output Parser

struct OutputParser {

    // [download]  45.2% of ~  150.00MiB at    5.20MiB/s ETA 00:15
    private static let progressRegex = try! NSRegularExpression(
        pattern: #"\[download\]\s+([\d.]+)%\s+of\s+~?\s*([\d.]+\S+)\s+at\s+([\d.]+\S+/s)\s+ETA\s+(\S+)"#
    )

    // [download]  45.2% of   (fallback without speed/ETA, e.g. fragment-based)
    private static let progressFallbackRegex = try! NSRegularExpression(
        pattern: #"\[download\]\s+([\d.]+)%"#
    )

    // [download] Destination: /path/to/Some Title.mp4
    private static let destinationRegex = try! NSRegularExpression(
        pattern: #"\[download\]\s+Destination:\s+(.+)"#
    )

    // [Merger] Merging formats into ...
    private static let mergerRegex = try! NSRegularExpression(
        pattern: #"\[Merger\]"#
    )

    // [ExtractAudio] Destination: ...
    private static let extractAudioRegex = try! NSRegularExpression(
        pattern: #"\[ExtractAudio\]"#
    )

    // ERROR: [generic] ...
    private static let errorRegex = try! NSRegularExpression(
        pattern: #"ERROR:\s+(.+)"#
    )

    // [download] 100% of ...  (already downloaded)
    private static let alreadyDownloadedRegex = try! NSRegularExpression(
        pattern: #"\[download\].*has already been downloaded"#
    )

    static func parse(line: String) -> OutputEvent? {
        let range = NSRange(line.startIndex..., in: line)

        // Full progress line with speed and ETA
        if let match = progressRegex.firstMatch(in: line, range: range) {
            let percentage = Double(extractGroup(match, group: 1, in: line) ?? "0") ?? 0
            let totalSize = extractGroup(match, group: 2, in: line)
            let speed = extractGroup(match, group: 3, in: line)
            let eta = extractGroup(match, group: 4, in: line)

            return .progress(DownloadProgress(
                percentage: min(percentage / 100.0, 1.0),
                totalSize: totalSize,
                speed: speed,
                eta: eta
            ))
        }

        // Fallback progress (no speed/ETA) — only if not matched above
        if let match = progressFallbackRegex.firstMatch(in: line, range: range),
           progressRegex.firstMatch(in: line, range: range) == nil {
            let percentage = Double(extractGroup(match, group: 1, in: line) ?? "0") ?? 0
            return .progress(DownloadProgress(
                percentage: min(percentage / 100.0, 1.0),
                totalSize: nil,
                speed: nil,
                eta: nil
            ))
        }

        // Destination path → extract title from filename
        if let match = destinationRegex.firstMatch(in: line, range: range) {
            let path = extractGroup(match, group: 1, in: line) ?? ""
            let filename = URL(fileURLWithPath: path)
                .deletingPathExtension()
                .lastPathComponent
            return .destination(filename)
        }

        // Already downloaded
        if alreadyDownloadedRegex.firstMatch(in: line, range: range) != nil {
            return .progress(DownloadProgress(percentage: 1.0, totalSize: nil, speed: nil, eta: nil))
        }

        // Merging phase
        if mergerRegex.firstMatch(in: line, range: range) != nil {
            return .merging
        }

        // Audio extraction phase
        if extractAudioRegex.firstMatch(in: line, range: range) != nil {
            return .converting
        }

        // Errors
        if let match = errorRegex.firstMatch(in: line, range: range) {
            let errorMsg = extractGroup(match, group: 1, in: line) ?? "Unknown error"
            return .error(errorMsg)
        }

        // Generic info lines
        if line.contains("[download]") || line.contains("[info]") || line.contains("[youtube]") {
            AppLogger.debug(.parser, "Info: \(line.prefix(120))")
            return .info(line)
        }

        AppLogger.debug(.parser, "Unrecognised line: \(line.prefix(120))")
        return nil
    }

    private static func extractGroup(
        _ match: NSTextCheckingResult,
        group: Int,
        in string: String
    ) -> String? {
        guard group < match.numberOfRanges else { return nil }
        let nsRange = match.range(at: group)
        guard nsRange.location != NSNotFound,
              let swiftRange = Range(nsRange, in: string)
        else { return nil }
        return String(string[swiftRange])
    }
}
